import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../../core/data/database.dart';
import '../../core/data/return_channel_dao.dart';
import '../../core/model/model.dart';
import '../../core/protocol/return_protocol.dart';
import 'gateway_bridge.dart';

typedef GatewayMeshSubmit = Future<void> Function(MeshEnvelope envelope);

/// Runs only on the phone explicitly configured as the internet gateway.
/// Commands are persisted before they are injected into the foreground mesh;
/// a process restart therefore resumes from the durable response outbox rather
/// than losing a signed authority response after the HTTP poll succeeds.
final class GatewayDownlinkPoller {
  GatewayDownlinkPoller({
    required this.bridge,
    required this.database,
    required this.siteId,
    required this.gatewaySessionId,
    required this.localEphemeralId,
    required this.submitToMesh,
    this.clockMs = _systemClock,
  });

  final GatewayBridge bridge;
  final MeshDatabase database;
  final String siteId;
  final String gatewaySessionId;
  final int localEphemeralId;
  final GatewayMeshSubmit submitToMesh;
  final int Function() clockMs;

  late final AuthorityResponseRepository _responses =
      AuthorityResponseRepository(database, clockMs: clockMs);
  Timer? _receiptTimer;
  bool _running = false;
  bool _polling = false;
  Future<void>? _receiptUploadFuture;
  final Set<int> _submittedObjectIds = {};
  String _cursor = '0';

  void start() {
    if (_running) return;
    _running = true;
    _receiptTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _scheduleReceiptUpload(),
    );
    unawaited(_pollLoop());
    _scheduleReceiptUpload();
  }

  void _scheduleReceiptUpload() {
    unawaited(uploadReadyReceipts());
  }

  Future<void> dispose() async {
    _running = false;
    _receiptTimer?.cancel();
    _receiptTimer = null;
    await _receiptUploadFuture;
  }

  Future<void> _pollLoop() async {
    while (_running) {
      if (_polling) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }
      _polling = true;
      try {
        final result = await bridge.pollAuthorityCommands(
          gatewaySessionId: gatewaySessionId,
          cursor: _cursor,
        );
        _cursor = result.cursor;
        for (final command in result.commands) {
          await _persistAndInject(command);
        }
        await _injectDurableResponses();
      } catch (_) {
        if (_running) await Future<void>.delayed(const Duration(seconds: 2));
      } finally {
        _polling = false;
      }
    }
  }

  Future<void> _injectDurableResponses() async {
    final now = clockMs();
    for (final row in await _responses.ready(nowMs: now)) {
      final objectId = row.meshObjectId;
      if (objectId == null || !_submittedObjectIds.add(objectId)) continue;
      if (row.expiresAtMs <= now) {
        await _responses.markExpired(row.responseId);
        await _reportProgress(
          responseId: row.responseId,
          state: 'EXPIRED',
          error: 'response_ttl',
        );
        _submittedObjectIds.remove(objectId);
        continue;
      }
      final signedBytes = Uint8List.fromList(row.signedPayload);
      final SignedResponderUpdateData signed;
      try {
        signed = ReturnProtocol.decodeSigned(signedBytes);
      } catch (_) {
        await _responses.markFailed(row.responseId, 'invalid signed payload');
        await _reportProgress(
          responseId: row.responseId,
          state: 'FAILED',
          error: 'invalid_signed_payload',
        );
        _submittedObjectIds.remove(objectId);
        continue;
      }
      final body = signed.body;
      try {
        await _reportProgress(
          responseId: row.responseId,
          state: 'MESH_QUEUED',
          returnHops: row.hopCount,
          retryCount: row.attempts,
        );
        await submitToMesh(
          MeshEnvelope(
            objectId: objectId,
            eventId: row.replyToEventId,
            siteId: body.siteId,
            roomId: '',
            createdAtMs: body.createdAtMs,
            expiresAtMs: min(row.expiresAtMs, body.expiresAtMs),
            hopCount: row.hopCount,
            hopLimit: const ReturnChannelConfig().returnHopLimit,
            priority: PriorityBand.p1High,
            payloadType: PayloadType.responderUpdate,
            payload: signedBytes,
            originEphemeralId: localEphemeralId,
            traceId: body.originalTraceId,
          ),
        );
      } catch (_) {
        _submittedObjectIds.remove(objectId);
      }
    }
  }

  Future<void> _persistAndInject(GatewayResponseCommand command) async {
    final signedBytes = Uint8List.fromList(command.signedPayload);
    final SignedResponderUpdateData signed;
    try {
      signed = ReturnProtocol.decodeSigned(signedBytes);
    } catch (_) {
      return;
    }
    final body = signed.body;
    final now = clockMs();
    if (body.siteId != siteId ||
        body.responseId != command.responseId ||
        body.replyToEventId != command.replyToEventId ||
        body.destinationEphemeralId != command.destinationEphemeralId ||
        body.expiresAtMs <= now) {
      return;
    }
    final existing = await _responses.get(body.responseId);
    if (existing?.state == 'DELIVERED' || existing?.state == 'EXPIRED') return;
    final objectId = existing?.meshObjectId ?? _newObjectId();
    await _responses.enqueue(
      responseId: body.responseId,
      replyToEventId: body.replyToEventId,
      destinationEphemeralId: body.destinationEphemeralId,
      signedPayload: signedBytes,
      meshObjectId: objectId,
      hopCount: existing?.hopCount ?? 0,
      createdAtMs: body.createdAtMs,
      expiresAtMs: body.expiresAtMs,
      traceId: body.originalTraceId,
    );

    // The server state transition is deliberately after local persistence.
    // A successful poll followed by process death remains recoverable.
    final acknowledged = await bridge.acknowledgeAuthorityCommand(
      gatewaySessionId: gatewaySessionId,
      responseId: body.responseId,
      meshObjectId: objectId,
    );
    if (acknowledged) {
      await _reportProgress(
        responseId: body.responseId,
        state: 'MESH_QUEUED',
        returnHops: existing?.hopCount ?? 0,
        retryCount: existing?.attempts ?? 0,
      );
    }
    if (!_submittedObjectIds.add(objectId)) return;
    try {
      await submitToMesh(
        MeshEnvelope(
          objectId: objectId,
          eventId: body.replyToEventId,
          siteId: body.siteId,
          roomId: '',
          createdAtMs: body.createdAtMs,
          expiresAtMs: body.expiresAtMs,
          hopCount: existing?.hopCount ?? 0,
          hopLimit: const ReturnChannelConfig().returnHopLimit,
          priority: PriorityBand.p1High,
          payloadType: PayloadType.responderUpdate,
          payload: signedBytes,
          originEphemeralId: localEphemeralId,
          traceId: body.originalTraceId,
        ),
      );
    } catch (_) {
      _submittedObjectIds.remove(objectId);
      // Keep the durable READY row for the next poll/restart. The dashboard
      // remains at truthful gateway custody rather than claiming forwarding.
      await _reportProgress(
        responseId: body.responseId,
        state: 'MESH_QUEUED',
        routeMode: 'retry',
        retryCount: existing?.attempts ?? 0,
        error: 'mesh_injection_pending',
      );
    }
  }

  Future<void> handleReceipt(AckMessageData receipt) async {
    if (!_running || receipt.kind != AckKind.responseDelivered) return;
    await _responses.enqueueReceipt(
      ResponseReceiptsCompanion.insert(
        receiptId: receipt.ackId,
        responseId: receipt.responseId,
        replyToEventId: receipt.replyToEventId,
        senderEphemeralId: receipt.senderEphemeralId,
        createdAtMs: receipt.createdAtMs,
      ),
    );
    await _reportProgress(
      responseId: receipt.responseId,
      state: 'SENDER_DELIVERED',
      receiptId: receipt.ackId,
      replyToEventId: receipt.replyToEventId,
      senderEphemeralId: receipt.senderEphemeralId,
    );
    await uploadReadyReceipts();
  }

  Future<void> uploadReadyReceipts() {
    if (!_running) return Future<void>.value();
    final existing = _receiptUploadFuture;
    if (existing != null) return existing;
    final future = _uploadReadyReceipts();
    _receiptUploadFuture = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_receiptUploadFuture, future)) {
          _receiptUploadFuture = null;
        }
      }),
    );
    return future;
  }

  Future<void> _uploadReadyReceipts() async {
    for (final receipt in await _responses.readyReceipts()) {
      await _reportProgress(
        responseId: receipt.responseId,
        state: 'SENDER_DELIVERED',
        receiptId: receipt.receiptId,
        replyToEventId: receipt.replyToEventId,
        senderEphemeralId: receipt.senderEphemeralId,
      );
      final uploaded = await bridge.uploadResponseReceipt(
        responseId: receipt.responseId,
        receiptId: receipt.receiptId,
        replyToEventId: receipt.replyToEventId,
        senderEphemeralId: receipt.senderEphemeralId,
        createdAtMs: receipt.createdAtMs,
      );
      if (uploaded) await _responses.markReceiptUploaded(receipt.receiptId);
    }
  }

  Future<void> _reportProgress({
    required String responseId,
    required String state,
    String? routeMode,
    int? returnHops,
    int? retryCount,
    String? error,
    String? receiptId,
    String? replyToEventId,
    int? senderEphemeralId,
  }) async {
    try {
      await bridge.reportAuthorityResponseProgress(
        responseId: responseId,
        gatewaySessionId: gatewaySessionId,
        state: state,
        routeMode: routeMode,
        returnHops: returnHops,
        retryCount: retryCount,
        error: error,
        receiptId: receiptId,
        replyToEventId: replyToEventId,
        senderEphemeralId: senderEphemeralId,
      );
    } catch (_) {
      // Progress is advisory and retried by the durable receipt/mesh loops;
      // never drop the signed response because the dashboard is unavailable.
    }
  }

  int _newObjectId() {
    final value =
        (Random.secure().nextInt(1 << 31) << 32) |
        Random.secure().nextInt(1 << 32);
    return value == 0 ? 1 : value;
  }

  static int _systemClock() => DateTime.now().millisecondsSinceEpoch;
}
