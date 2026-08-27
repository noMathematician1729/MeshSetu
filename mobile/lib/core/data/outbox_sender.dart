import 'dart:async';

import 'package:drift/drift.dart';

import '../model/model.dart';
import '../protocol/relay_engine.dart';
import 'database.dart';

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
    this.expirySweepInterval = const Duration(seconds: 10),
    this.onDeliveryFailure,
    this.onDiagnostic,
  }) : assert(maxAttempts > 0),
       assert(retryBaseDelay > Duration.zero),
       assert(expirySweepInterval > Duration.zero);

  final MeshDatabase _db;
  final Future<void> Function(MeshEnvelope envelope) _send;
  final String siteId;
  final int localEphemeralId;
  final int maxAttempts;
  final Duration retryBaseDelay;

  /// How often relaying rows past their expiry are swept to 'expired'. This
  /// is the backstop for a peer that never sends a custody ack and never
  /// times out at the relay-engine level either (e.g. the BLE write never
  /// completed at all) — without it, such a row has no path off 'relaying'
  /// and renders as an ungreen "Relaying now" card forever.
  final Duration expirySweepInterval;
  final void Function(OutboxEvent row, Object error)? onDeliveryFailure;

  /// Fired for conditions worth surfacing to logs/telemetry that are not a
  /// delivery failure of a specific row — e.g. an ack/expiry metric whose
  /// objectId does not match any row in this instance's own [siteId], which
  /// would otherwise be silently dropped by the site-scoped update in
  /// [_markByObjectId] and look identical to "no such object".
  final void Function(String kind, {String? detail})? onDiagnostic;

  StreamSubscription<List<OutboxEvent>>? _sub;
  final Set<String> _draining = {};
  final Map<String, Timer> _retryTimers = {};
  final Map<String, int> _retryAfterMs = {};
  final Map<String, int> _attempts = {};
  bool _disposed = false;
  Timer? _expirySweepTimer;

  void start() {
    _disposed = false;
    unawaited(_recoverAndListen());
    _expirySweepTimer?.cancel();
    _expirySweepTimer = Timer.periodic(
      expirySweepInterval,
      (_) => unawaited(_sweepExpiredRelaying()),
    );
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

  /// Scoped deliberately to this site's 'relaying' rows only — not the
  /// unscoped [MeshDatabase.expireOverdue], which would also touch
  /// unfinalized 'created' drafts and rows belonging to other sites.
  Future<void> _sweepExpiredRelaying() async {
    if (_disposed) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows =
        await (_db.select(_db.outboxEvents)..where(
              (t) =>
                  t.siteId.equals(siteId) &
                  t.state.equals('relaying') &
                  t.expiresAtMs.isSmallerOrEqualValue(now),
            ))
            .get();
    for (final row in rows) {
      _ackTimeoutAttempts.remove(row.objectId);
      await _db.markState(row.eventId, 'expired', now);
    }
  }

  /// Bounded ack-timeout retry counter, keyed by durable objectId rather
  /// than eventId: the relay engine's own timeout is a transport-level
  /// signal per object, independent of the send-callback attempt counter
  /// in [_attempts].
  final Map<int, int> _ackTimeoutAttempts = {};

  /// Maximum times a relaying row is returned to READY after its custody
  /// ack never arrived before this device gives up and marks it FAILED.
  /// Without this bound (and without [ack_timeout] being handled at all),
  /// a row with no reachable peer stays on 'relaying' forever — rendered
  /// as an ungreen "Relaying now" card that never changes.
  static const int maxAckTimeoutAttempts = 5;

  Future<void> onMetrics(List<RelayMetric> metrics) async {
    for (final m in metrics) {
      final objectId = m.objectId;
      if (objectId == null) continue;
      if (m.kind == 'ack') {
        _ackTimeoutAttempts.remove(objectId);
        await _markByObjectId(objectId, 'acked');
      } else if (m.kind == 'expired') {
        _ackTimeoutAttempts.remove(objectId);
        await _markByObjectId(objectId, 'expired');
      } else if (m.kind == 'ack_timeout') {
        await _handleAckTimeout(objectId);
      }
    }
  }

  /// The relay engine already retries the BLE send internally on its own
  /// timeout; this makes that retry visible and bounded at the outbox level
  /// so a peer that never acknowledges custody cannot leave the row stuck
  /// on 'relaying' indefinitely. [expireOverdue] remains the backstop for
  /// rows whose response window has passed entirely.
  Future<void> _handleAckTimeout(int objectId) async {
    final row =
        await (_db.select(_db.outboxEvents)..where(
              (t) =>
                  t.siteId.equals(siteId) &
                  t.objectId.equals(objectId) &
                  t.state.equals('relaying'),
            ))
            .getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (row.expiresAtMs <= now) {
      _ackTimeoutAttempts.remove(objectId);
      await _db.markState(row.eventId, 'expired', now);
      return;
    }
    final attempt = (_ackTimeoutAttempts[objectId] ?? 0) + 1;
    if (attempt >= maxAckTimeoutAttempts) {
      _ackTimeoutAttempts.remove(objectId);
      await _db.markState(row.eventId, 'failed', now);
      onDeliveryFailure?.call(
        row,
        StateError('no custody acknowledgement after $attempt attempts'),
      );
      return;
    }
    _ackTimeoutAttempts[objectId] = attempt;
    // Returning to 'ready' lets watchReady() redrain it through the normal
    // path, which re-checks expiresAtMs before sending again.
    await _db.markState(row.eventId, 'ready', now);
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
    final updated =
        await (_db.update(_db.outboxEvents)..where(
              (t) =>
                  t.siteId.equals(siteId) &
                  t.objectId.equals(objectId) &
                  t.state.equals('relaying'),
            ))
            .write(
              OutboxEventsCompanion(
                state: Value(state),
                updatedAtMs: Value(now),
              ),
            );
    if (updated > 0) return;
    // Nothing matched this site's own relaying row for that objectId. This
    // metric may simply be for a different local row (already acked,
    // already expired, or genuinely unknown) — but it may also be a
    // namespace mismatch: an ack/expiry decoded for the right objectId but
    // filed under a different siteId, which would otherwise be swallowed
    // here identically to "no such object" and never surfaced anywhere.
    final mismatched =
        await (_db.select(_db.outboxEvents)..where(
              (t) =>
                  t.objectId.equals(objectId) & t.siteId.equals(siteId).not(),
            ))
            .getSingleOrNull();
    if (mismatched != null) {
      onDiagnostic?.call(
        'ack_site_mismatch',
        detail: 'objectId matched a row under a different active site',
      );
    }
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
      final attempt = (_attempts[row.eventId] ?? 0) + 1;
      _attempts[row.eventId] = attempt;
      if (attempt >= maxAttempts) {
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
      final delay = retryBaseDelay * (1 << (attempt - 1).clamp(0, 4));
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
        // Bulk band so a multi-kilobyte voice note is preempted mid-transfer
        // by room text and SOS traffic (`MeshTransportCoordinator` checks
        // `hasHigherPriorityThan` between frame writes).
        PayloadType.roomVoice => PriorityBand.p3Bulk,
        _ => PriorityBand.p2Normal,
      };

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    _expirySweepTimer?.cancel();
    _expirySweepTimer = null;
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _retryAfterMs.clear();
    _attempts.clear();
    _ackTimeoutAttempts.clear();
    _draining.clear();
  }
}
