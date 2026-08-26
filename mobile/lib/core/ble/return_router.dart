import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import '../ble/mesh_transport.dart';
import '../data/database.dart';
import '../data/return_channel_dao.dart';
import '../model/model.dart';
import '../protocol/authority_signature.dart';
import '../protocol/return_protocol.dart';

/// Technical route modes intentionally remain telemetry, not operator-facing
/// identity. A response is successful only after sender verification and an
/// application receipt, not after a local BLE write.
enum ReturnRouteMode {
  liveConnection,
  reverseCache,
  alternateCache,
  fallback,
  retry,
}

typedef VerifiedResponseListener =
    FutureOr<void> Function(ResponderUpdateBodyData response);

final class ReturnRouter {
  ReturnRouter({
    required this.transport,
    required this.routes,
    required this.responses,
    required this.localEphemeralId,
    required this.trustSnapshot,
    required this.isKnownSosEvent,
    this.config = const ReturnChannelConfig(),
    this.clockMs = _systemClock,
    this.onVerifiedResponse,
    this.onMetric,
  });

  final MeshTransportCoordinator transport;
  final ReverseRouteRepository routes;
  final AuthorityResponseRepository responses;
  final int localEphemeralId;
  final Future<AuthorityTrustSnapshot?> Function() trustSnapshot;
  final Future<bool> Function(String eventId) isKnownSosEvent;
  final ReturnChannelConfig config;
  final int Function() clockMs;
  final VerifiedResponseListener? onVerifiedResponse;
  final void Function(String kind, {String? detail, int? value})? onMetric;

  final Map<String, int> _seenResponses = {};
  final Random _random = Random.secure();

  /// Called after the relay has authenticated and persisted a responder
  /// envelope. It is safe to call outside the relay lock; [sendToPeer] takes
  /// the transport lock itself.
  Future<void> handleResponderUpdate({
    required MeshEnvelope envelope,
    required String fromPeerId,
    required Uint8List encryptedBytes,
  }) async {
    final now = clockMs();
    if (envelope.expiresAtMs <= now || envelope.hopCount >= envelope.hopLimit) {
      _metric('response_expired', value: envelope.objectId);
      return;
    }
    final SignedResponderUpdateData signed;
    try {
      signed = ReturnProtocol.decodeSigned(envelope.payload);
    } catch (error) {
      _metric('response_invalid_payload', detail: '$error');
      return;
    }
    final body = signed.body;
    if (body.siteId != envelope.siteId || body.expiresAtMs <= now) {
      _metric('response_expired', detail: 'body_scope_or_expiry');
      return;
    }
    final seen = _seenResponses[body.responseId];
    if (seen != null && seen > now) {
      _metric('response_duplicate_drop');
      return;
    }
    _seenResponses[body.responseId] = body.expiresAtMs;
    _pruneSeen(now);

    if (body.destinationEphemeralId == localEphemeralId) {
      await _deliverToSender(signed, envelope);
      return;
    }

    final ingress = transport.peerDirectory.entryForPeer(fromPeerId);
    final ingressEphemeralId = ingress?.ephemeralNodeId;
    await responses.enqueue(
      responseId: body.responseId,
      replyToEventId: body.replyToEventId,
      destinationEphemeralId: body.destinationEphemeralId,
      signedPayload: envelope.payload,
      meshObjectId: envelope.objectId,
      hopCount: envelope.hopCount,
      createdAtMs: body.createdAtMs,
      expiresAtMs: min(body.expiresAtMs, envelope.expiresAtMs),
      traceId: body.originalTraceId,
    );
    await _forward(
      envelope: envelope,
      signedPayload: envelope.payload,
      ingressEphemeralId: ingressEphemeralId,
      responseId: body.responseId,
      nowMs: now,
    );
  }

  Future<void> retryDue() async {
    final now = clockMs();
    for (final row in await responses.ready(nowMs: now)) {
      if (row.expiresAtMs <= now) {
        await responses.markExpired(row.responseId);
        _metric('response_expired');
        continue;
      }
      final signedBytes = row.signedPayload;
      final SignedResponderUpdateData signed;
      try {
        signed = ReturnProtocol.decodeSigned(signedBytes);
      } catch (_) {
        await responses.markFailed(row.responseId, 'invalid signed payload');
        continue;
      }
      final envelope = MeshEnvelope(
        objectId: row.meshObjectId ?? _newObjectId(),
        eventId: signed.body.replyToEventId,
        siteId: signed.body.siteId,
        roomId: '',
        createdAtMs: signed.body.createdAtMs,
        expiresAtMs: min(row.expiresAtMs, signed.body.expiresAtMs),
        hopCount: row.hopCount,
        hopLimit: config.returnHopLimit,
        priority: PriorityBand.p1High,
        payloadType: PayloadType.responderUpdate,
        payload: signedBytes,
        originEphemeralId: localEphemeralId,
        traceId: signed.body.originalTraceId,
      );
      await _forward(
        envelope: envelope,
        signedPayload: signedBytes,
        responseId: row.responseId,
        nowMs: now,
      );
    }
  }

  Future<void> _deliverToSender(
    SignedResponderUpdateData signed,
    MeshEnvelope envelope,
  ) async {
    final body = signed.body;
    final trust = await trustSnapshot();
    if (trust == null ||
        trust.siteId != body.siteId ||
        trust.keyId != signed.authorityKeyId ||
        signed.algorithm != ReturnSignatureAlgorithm.ecdsaP256Sha256) {
      _metric('authority_signature_rejected', detail: 'trust_material');
      return;
    }
    final valid = await const AuthoritySignatureVerifier().verify(
      publicKey: trust.publicKey,
      body: signed.bodyBytes,
      signature: signed.authoritySignature,
    );
    if (!valid) {
      _metric(
        'authority_signature_rejected',
        detail: 'cryptographic_verification',
      );
      return;
    }
    if (utf8.encode(body.messageText).length >
            ReturnProtocol.maxMessageUtf8Bytes ||
        !(await isKnownSosEvent(body.replyToEventId))) {
      _metric('authority_signature_rejected', detail: 'event_or_message_guard');
      return;
    }
    final inserted = await responses.persistVerified(
      AuthorityInboxCompanion.insert(
        responseId: body.responseId,
        replyToEventId: body.replyToEventId,
        siteId: body.siteId,
        responseType: body.type.name,
        messageText: body.messageText,
        createdAtMs: body.createdAtMs,
        expiresAtMs: body.expiresAtMs,
        receivedAtMs: clockMs(),
        originalTraceId: Value(body.originalTraceId),
      ),
    );
    if (inserted) {
      await onVerifiedResponse?.call(body);
      _metric('response_delivered');
    } else {
      _metric('response_duplicate_drop');
    }
    await _enqueueDeliveryReceipt(body, envelope.objectId);
  }

  Future<void> _enqueueDeliveryReceipt(
    ResponderUpdateBodyData body,
    int ackedObjectId,
  ) async {
    final ackId = '${body.responseId}:$localEphemeralId';
    await responses.enqueueReceipt(
      ResponseReceiptsCompanion.insert(
        receiptId: ackId,
        responseId: body.responseId,
        replyToEventId: body.replyToEventId,
        senderEphemeralId: localEphemeralId,
        createdAtMs: clockMs(),
      ),
    );
    final now = clockMs();
    final receipt = AckMessageData(
      ackId: ackId,
      kind: AckKind.responseDelivered,
      ackedObjectId: ackedObjectId,
      responseId: body.responseId,
      replyToEventId: body.replyToEventId,
      senderEphemeralId: localEphemeralId,
      createdAtMs: now,
      expiresAtMs: min(body.expiresAtMs, now + config.responseTtlMs),
    );
    final envelope = MeshEnvelope(
      objectId: _newObjectId(),
      eventId: body.replyToEventId,
      siteId: body.siteId,
      roomId: '',
      createdAtMs: now,
      expiresAtMs: receipt.expiresAtMs,
      hopCount: 0,
      hopLimit: config.returnHopLimit,
      priority: PriorityBand.p0Critical,
      payloadType: PayloadType.ack,
      payload: ReturnProtocol.encodeAck(receipt),
      originEphemeralId: localEphemeralId,
      traceId: body.originalTraceId,
    );
    await transport.send(envelope);
  }

  Future<void> _forward({
    required MeshEnvelope envelope,
    required Uint8List signedPayload,
    required String responseId,
    required int nowMs,
    int? ingressEphemeralId,
  }) async {
    if (envelope.hopCount >= envelope.hopLimit) {
      await responses.markExpired(responseId);
      _metric('response_expired', detail: 'hop_limit');
      return;
    }
    final routesForResponse = (await routes.candidates(
      siteId: envelope.siteId,
      eventId: envelope.eventId,
      originEphemeralId: _destinationFromPayload(signedPayload),
      nowMs: nowMs,
    )).where((route) => route.previousPeerEphemeralId != ingressEphemeralId);
    final candidates = routesForResponse.toList();
    for (var index = 0; index < candidates.length; index++) {
      final route = candidates[index];
      final ok = await _sendNextHop(envelope, route.previousPeerEphemeralId);
      if (ok) {
        await routes.markReachable(route, nowMs: nowMs);
        await responses.markForwarding(
          responseId,
          index == 0
              ? ReturnRouteMode.reverseCache.name
              : ReturnRouteMode.alternateCache.name,
        );
        _metric(
          'response_forwarded',
          value: envelope.hopCount + 1,
          detail: index == 0
              ? ReturnRouteMode.reverseCache.name
              : ReturnRouteMode.alternateCache.name,
        );
        return;
      }
      await routes.markFailure(route);
    }

    final attempted = candidates
        .map((candidate) => candidate.previousPeerEphemeralId)
        .toSet();
    final fallbackPeers = transport.peerDirectory
        .readyPeers()
        .where(
          (peer) =>
              peer.ephemeralNodeId != ingressEphemeralId &&
              !attempted.contains(peer.ephemeralNodeId),
        )
        .take(config.maxFallbackPeers);
    for (final peer in fallbackPeers) {
      if (await _sendNextHop(envelope, peer.ephemeralNodeId)) {
        await responses.markForwarding(
          responseId,
          ReturnRouteMode.fallback.name,
        );
        _metric('fallback_forwarded', value: envelope.hopCount + 1);
        return;
      }
    }
    final nextAttempt = nowMs + config.backoffMs.first;
    await responses.markRetry(
      responseId,
      nextAttemptAtMs: nextAttempt,
      error: 'no eligible return peer',
    );
    _metric('reverse_route_miss', detail: 'durable_retry');
  }

  Future<bool> _sendNextHop(MeshEnvelope envelope, int peerEphemeralId) async {
    final next = envelope.copyWith(hopCount: envelope.hopCount + 1);
    final encrypted = await transport.relay.crypto.encrypt(next);
    return transport.sendToPeer(peerEphemeralId, encrypted);
  }

  int _destinationFromPayload(Uint8List signedPayload) {
    try {
      return ReturnProtocol.decodeSigned(
        signedPayload,
      ).body.destinationEphemeralId;
    } catch (_) {
      return -1;
    }
  }

  void _pruneSeen(int nowMs) {
    _seenResponses.removeWhere((_, expiry) => expiry <= nowMs);
    while (_seenResponses.length > config.maxResponseCache) {
      _seenResponses.remove(_seenResponses.keys.first);
    }
  }

  void _metric(String kind, {String? detail, int? value}) =>
      onMetric?.call(kind, detail: detail, value: value);

  int _newObjectId() {
    final high = _random.nextInt(1 << 31);
    final low = _random.nextInt(1 << 32);
    final value = (high << 32) | low;
    return value == 0 ? 1 : value;
  }

  static int _systemClock() => DateTime.now().millisecondsSinceEpoch;
}
