import 'dart:async';

import 'package:drift/drift.dart';

import '../model/model.dart';
import '../protocol/relay_engine.dart';
import 'database.dart';

/// Thrown when an outbox row cannot be handed to the mesh right now for a
/// reason that is expected to clear on its own — the BLE foreground service
/// is not running yet, or it has not acknowledged the submission.
///
/// This is deliberately distinct from a rejection: a room message or SOS must
/// not be marked permanently `failed` just because the radio was still
/// starting when the user hit send. [OutboxSender] retries these without
/// consuming a delivery attempt.
class MeshTransportUnavailable implements Exception {
  const MeshTransportUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'MeshTransportUnavailable: $reason';
}

/// Drains `state = ready` [OutboxEvents] rows through a caller-supplied
/// `send` callback and reflects ACK/expiry metrics back onto the row,
/// implementing the CREATED -> READY -> RELAYING -> ACKED|EXPIRED state
/// machine from Bible §2.5. Shared by `feature/sos` and `feature/rooms` —
/// both just insert a `ready` row and this drains it.
///
/// `send` is a callback rather than a direct `MeshTransportCoordinator`
/// reference because the coordinator lives in the `flutter_foreground_task`
/// background isolate (`app/mesh_event_controller.dart`), not the UI
/// isolate this repository runs in — `app/mesh_bridge.dart` wires the two
/// together over the plugin's isolate message channel.
class OutboxSender {
  OutboxSender(
    this._db,
    this._send, {
    required this.siteId,
    required this.localEphemeralId,
    this.maxAttempts = 5,
    this.retryBaseDelay = const Duration(seconds: 1),
    this.transportRetryDelay = const Duration(seconds: 5),
    this.onDeliveryFailure,
  }) : assert(maxAttempts > 0),
       assert(retryBaseDelay > Duration.zero);

  final MeshDatabase _db;
  final Future<void> Function(MeshEnvelope envelope) _send;
  final String siteId;
  final int localEphemeralId;
  final int maxAttempts;
  final Duration retryBaseDelay;

  /// Retry spacing used while the transport itself is unavailable, where
  /// attempts are not counted against [maxAttempts].
  final Duration transportRetryDelay;
  final void Function(OutboxEvent row, Object error)? onDeliveryFailure;

  StreamSubscription<List<OutboxEvent>>? _sub;
  final Set<String> _draining = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, int> _retryAfterMs = {};
  final Map<String, int> _attempts = {};
  bool _disposed = false;

  void start() {
    _disposed = false;
    unawaited(_recoverAndListen());
  }

  Future<void> _recoverAndListen() async {
    await (_db.update(
          _db.outboxEvents,
        )..where((t) => (t.siteId.equals(siteId) & t.state.equals('relaying'))))
        .write(
          OutboxEventsCompanion(
            state: const Value('ready'),
            updatedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    if (_disposed) return;
    _sub = _db.watchReady(siteId).listen((rows) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final row in rows) {
        if ((_retryAfterMs[row.eventId] ?? 0) > now) continue;
        if (_draining.add(row.eventId)) unawaited(_drainOnce(row));
      }
    });
  }

  Future<void> onMetrics(List<RelayMetric> metrics) async {
    for (final m in metrics) {
      final objectId = m.objectId;
      if (objectId == null) continue;
      if (m.kind == 'ack') {
        await _markByObjectId(objectId, 'acked');
      } else if (m.kind == 'expired') {
        await _markByObjectId(objectId, 'expired');
      }
    }
  }

  /// Reconciles a foreground acceptance that arrived after the submission
  /// completer timed out. The row may already have been returned to READY;
  /// accepting it as RELAYING prevents a duplicate submission while custody
  /// ACK handling remains unchanged.
  Future<void> onSubmissionResult(
    int objectId, {
    required bool accepted,
  }) async {
    if (!accepted) return;
    final row =
        await (_db.select(_db.outboxEvents)..where(
              (t) => t.siteId.equals(siteId) & t.objectId.equals(objectId),
            ))
            .getSingleOrNull();
    if (row == null || row.state == 'acked' || row.state == 'expired') return;
    _retryAfterMs.remove(row.eventId);
    _retryTimers.remove(row.eventId)?.cancel();
    _attempts.remove(row.eventId);
    if (row.state == 'ready') {
      await _db.markState(
        row.eventId,
        'relaying',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _markByObjectId(int objectId, String state) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.outboxEvents)..where(
          (t) =>
              t.siteId.equals(siteId) &
              t.objectId.equals(objectId) &
              t.state.equals('relaying'),
        ))
        .write(
          OutboxEventsCompanion(state: Value(state), updatedAtMs: Value(now)),
        );
  }

  Future<void> _drainOnce(OutboxEvent row) async {
    try {
      final objectId = row.objectId;
      final payload = row.payload;
      if (objectId == null || payload == null) {
        await _db.markState(
          row.eventId,
          'failed',
          DateTime.now().millisecondsSinceEpoch,
        );
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      if (row.expiresAtMs <= now) {
        await _db.markState(row.eventId, 'expired', now);
        return;
      }
      await _db.markState(row.eventId, 'relaying', now);
      await _send(
        MeshEnvelope(
          objectId: objectId,
          eventId: row.eventId,
          siteId: row.siteId,
          roomId: row.roomId,
          createdAtMs: row.createdAtMs,
          expiresAtMs: row.expiresAtMs,
          hopCount: 0,
          hopLimit: 4,
          priority: _priorityFor(row.payloadType),
          payloadType: PayloadType.values.byName(row.payloadType),
          payload: Uint8List.fromList(payload),
          originEphemeralId: localEphemeralId,
        ),
      );
      _attempts.remove(row.eventId);
    } catch (error) {
      // A radio that has not started yet is not a delivery failure. Keeping
      // the attempt counter untouched means a message typed a moment before
      // Event Mode came up still goes out, instead of dying after five fast
      // retries and needing the user to retype it.
      final consumesAttempt = error is! MeshTransportUnavailable;
      final attempt = consumesAttempt
          ? (_attempts[row.eventId] ?? 0) + 1
          : (_attempts[row.eventId] ?? 0);
      if (consumesAttempt) _attempts[row.eventId] = attempt;
      if (consumesAttempt && attempt >= maxAttempts) {
        _attempts.remove(row.eventId);
        await _db.markState(
          row.eventId,
          'failed',
          DateTime.now().millisecondsSinceEpoch,
        );
        onDeliveryFailure?.call(row, error);
        return;
      }
      // Return rejected submissions to READY, but use exponential backoff so
      // a stopped foreground task cannot spin the same row forever. A later
      // bridge restart can drain the READY row again because the retry state
      // is deliberately local to this sender instance.
      final delay = consumesAttempt
          ? retryBaseDelay * (1 << (attempt - 1).clamp(0, 4))
          : transportRetryDelay;
      final retryAt =
          DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds;
      _retryAfterMs[row.eventId] = retryAt;
      await _db.markState(row.eventId, 'ready', retryAt);
      final timer = Timer(delay, () async {
        if (_disposed) return;
        _retryTimers.remove(row.eventId);
        _retryAfterMs.remove(row.eventId);
        final current = await (_db.select(
          _db.outboxEvents,
        )..where((t) => t.eventId.equals(row.eventId))).getSingleOrNull();
        if (current != null &&
            current.state == 'ready' &&
            _draining.add(row.eventId)) {
          unawaited(_drainOnce(current));
        }
      });
      _retryTimers[row.eventId]?.cancel();
      _retryTimers[row.eventId] = timer;
    } finally {
      _draining.remove(row.eventId);
    }
  }

  PriorityBand _priorityFor(String payloadType) =>
      switch (PayloadType.values.byName(payloadType)) {
        PayloadType.structuredSos => PriorityBand.p0Critical,
        PayloadType.responderUpdate => PriorityBand.p1High,
        PayloadType.voiceManifest ||
        PayloadType.voiceObject => PriorityBand.p2Normal,
        _ => PriorityBand.p2Normal,
      };

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _retryAfterMs.clear();
    _attempts.clear();
    _draining.clear();
  }
}
