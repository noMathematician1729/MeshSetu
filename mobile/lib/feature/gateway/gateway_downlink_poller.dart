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
      } catch (_) {
        if (_running) await Future<void>.delayed(const Duration(seconds: 2));
      } finally {
        _polling = false;
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
    await bridge.acknowledgeAuthorityCommand(
      gatewaySessionId: gatewaySessionId,
      responseId: body.responseId,
      meshObjectId: objectId,
    );
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
      // The durable READY row is retried by the foreground ReturnRouter.
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

  int _newObjectId() {
    final value =
        (Random.secure().nextInt(1 << 31) << 32) |
        Random.secure().nextInt(1 << 32);
    return value == 0 ? 1 : value;
  }

  static int _systemClock() => DateTime.now().millisecondsSinceEpoch;
}
