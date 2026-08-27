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

/// Privacy-safe lifecycle signal emitted by the foreground mesh isolate. It
/// contains only bounded protocol state, route mode, hop/retry counters, and
/// stable response identifiers needed by the gateway progress API.
final class AuthorityResponseProgress {
  const AuthorityResponseProgress({
    required this.responseId,
    required this.state,
    this.routeMode,
    this.returnHops,
    this.retryCount,
    this.error,
    this.receiptId,
    this.replyToEventId,
    this.senderEphemeralId,
    this.receiptCreatedAtMs,
  });

  final String responseId;
  final String state;
  final String? routeMode;
  final int? returnHops;
  final int? retryCount;
  final String? error;
  final String? receiptId;
  final String? replyToEventId;
  final int? senderEphemeralId;
  final int? receiptCreatedAtMs;
}

typedef AuthorityResponseProgressListener =
    FutureOr<void> Function(AuthorityResponseProgress progress);

typedef PeerHintConnector =
    Future<void> Function(String peerHint, int expectedEphemeralId);

final class ReturnRouter {
  ReturnRouter({
    required this.transport,
    required this.routes,
    required this.responses,
    required this.localEphemeralId,
    required this.trustSnapshot,
    required this.isKnownSosEvent,
    this.isLocallyAuthoredSosEvent,
    this.connectToPeerHint,
    this.config = const ReturnChannelConfig(),
    this.clockMs = _systemClock,
    this.onVerifiedResponse,
    this.onMetric,
    this.onProgress,
  });

  final MeshTransportCoordinator transport;
  final ReverseRouteRepository routes;
  final AuthorityResponseRepository responses;
  final int localEphemeralId;
  final Future<AuthorityTrustSnapshot?> Function() trustSnapshot;
  final Future<bool> Function(String eventId) isKnownSosEvent;
  final Future<bool> Function(String eventId)? isLocallyAuthoredSosEvent;
  final PeerHintConnector? connectToPeerHint;
  final ReturnChannelConfig config;
  final int Function() clockMs;
  final VerifiedResponseListener? onVerifiedResponse;
  final void Function(String kind, {String? detail, int? value})? onMetric;
  final AuthorityResponseProgressListener? onProgress;

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
    final SignedResponderUpdateData signed;
    try {
      // Decode only; the sender branch below verifies the exact body bytes
      // carried by this object and never verifies a reserialized message.
      signed = ReturnProtocol.decodeSigned(envelope.payload);
    } catch (error) {
      _metric('response_invalid_payload', detail: '$error');
      if (envelope.expiresAtMs <= now ||
          envelope.hopCount >= envelope.hopLimit) {
        _metric('response_expired', value: envelope.objectId);
      }
      return;
    }
    final body = signed.body;
    if (envelope.expiresAtMs <= now ||
        envelope.hopCount >= envelope.hopLimit ||
        body.expiresAtMs <= now) {
      await _expireResponse(body.responseId, detail: 'expired_or_hop_limit');
      _metric(
        'response_expired',
        value: envelope.objectId,
        detail: envelope.hopCount >= envelope.hopLimit
            ? 'hop_limit'
            : 'response_ttl',
      );
      return;
    }
    if (body.siteId != envelope.siteId) {
      await _failResponse(body.responseId, 'wrong_site');
      _metric('response_invalid_scope', detail: 'wrong_site');
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

  /// Gateway downlink injection uses this entry point rather than generic
  /// broadcast replication. It gives a gateway-as-destination the same
  /// trust/event/expiry/receipt path as a response received from a peer.
  Future<void> handleInjectedResponderUpdate(MeshEnvelope envelope) =>
      handleResponderUpdate(
        envelope: envelope,
        fromPeerId: '__gateway_origin__',
        encryptedBytes: Uint8List(0),
      );

  Future<void> retryDue() async {
    final now = clockMs();
    for (final row in await responses.ready(nowMs: now)) {
      if (row.expiresAtMs <= now) {
        await _expireResponse(row.responseId, detail: 'response_ttl');
        _metric('response_expired');
        continue;
      }
      final signedBytes = row.signedPayload;
      final SignedResponderUpdateData signed;
      try {
        signed = ReturnProtocol.decodeSigned(signedBytes);
      } catch (_) {
        await _failResponse(row.responseId, 'invalid_signed_payload');
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
    final trustFailure = switch (trust) {
      null => 'authority_trust_missing',
      _ when trust.siteId != body.siteId => 'authority_trust_rejected_site',
      _ when trust.keyId != signed.authorityKeyId =>
        'authority_trust_rejected_key_id',
      _ when signed.algorithm != ReturnSignatureAlgorithm.ecdsaP256Sha256 =>
        'authority_trust_rejected_algorithm',
      _ => null,
    };
    if (trustFailure != null) {
      await _failResponse(body.responseId, 'authority_trust_rejected');
      // Deliberately identify only the guard category. Do not emit raw signed
      // bodies, signatures, or public-key material into protocol metrics.
      _metric('authority_signature_rejected', detail: trustFailure);
      return;
    }
    final verifiedTrust = trust!;
    final valid = await const AuthoritySignatureVerifier().verify(
      publicKey: verifiedTrust.publicKey,
      body: signed.bodyBytes,
      signature: signed.authoritySignature,
    );
    if (!valid) {
      await _failResponse(body.responseId, 'authority_signature_rejected');
      _metric(
        'authority_signature_rejected',
        detail: 'cryptographic_verification',
      );
      return;
    }
    final knownEvent = await isKnownSosEvent(body.replyToEventId);
    final locallyAuthored =
        !knownEvent &&
        (await isLocallyAuthoredSosEvent?.call(body.replyToEventId) ?? false);
    if (utf8.encode(body.messageText).length >
            ReturnProtocol.maxMessageUtf8Bytes ||
        (!knownEvent && !locallyAuthored)) {
      await _failResponse(body.responseId, 'event_or_message_guard');
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
    await _progress(
      AuthorityResponseProgress(
        responseId: body.responseId,
        state: 'SENDER_DELIVERED',
        returnHops: envelope.hopCount,
        receiptId: '${body.responseId}:$localEphemeralId',
        replyToEventId: body.replyToEventId,
        senderEphemeralId: localEphemeralId,
        receiptCreatedAtMs: clockMs(),
      ),
    );
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
      await _expireResponse(responseId, detail: 'hop_limit');
      _metric('response_expired', detail: 'hop_limit');
      return;
    }
    final destinationEphemeralId = _destinationFromPayload(signedPayload);
    var candidates =
        (await routes.candidates(
              siteId: envelope.siteId,
              eventId: envelope.eventId,
              originEphemeralId: destinationEphemeralId,
              nowMs: nowMs,
            ))
            .where(
              (route) => route.previousPeerEphemeralId != ingressEphemeralId,
            )
            .toList();
    if (candidates.isEmpty) {
      candidates =
          (await routes.candidatesForDestination(
                siteId: envelope.siteId,
                originEphemeralId: destinationEphemeralId,
                nowMs: nowMs,
              ))
              .where(
                (route) => route.previousPeerEphemeralId != ingressEphemeralId,
              )
              .toList();
      if (candidates.isNotEmpty) {
        _metric('reverse_route_event_converged', detail: 'destination_scoped');
      }
    }
    for (var index = 0; index < candidates.length; index++) {
      final route = candidates[index];
      final ok = await _sendRoute(envelope, route);
      if (ok) {
        await routes.markReachable(route, nowMs: nowMs);
        final routeMode = index == 0
            ? ReturnRouteMode.reverseCache.name
            : ReturnRouteMode.alternateCache.name;
        await responses.markForwarding(responseId, routeMode);
        await _progress(
          AuthorityResponseProgress(
            responseId: responseId,
            state: 'FORWARDING',
            routeMode: routeMode,
            returnHops: envelope.hopCount + 1,
            retryCount: (await responses.get(responseId))?.attempts ?? 0,
          ),
        );
        _metric(
          'response_forwarded',
          value: envelope.hopCount + 1,
          detail: routeMode,
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
        await _progress(
          AuthorityResponseProgress(
            responseId: responseId,
            state: 'FORWARDING',
            routeMode: ReturnRouteMode.fallback.name,
            returnHops: envelope.hopCount + 1,
            retryCount: (await responses.get(responseId))?.attempts ?? 0,
          ),
        );
        _metric('fallback_forwarded', value: envelope.hopCount + 1);
        return;
      }
    }
    final current = await responses.get(responseId);
    final retryCount = (current?.attempts ?? 0) + 1;
    await responses.incrementAttempt(responseId);
    final maxRetries = max(1, config.backoffMs.length);
    if (retryCount >= maxRetries) {
      await responses.markFailed(responseId, 'no eligible return peer');
      await _progress(
        AuthorityResponseProgress(
          responseId: responseId,
          state: 'FAILED',
          routeMode: ReturnRouteMode.retry.name,
          returnHops: envelope.hopCount,
          retryCount: retryCount,
          error: 'no_eligible_return_route',
        ),
      );
      _metric('reverse_route_failed', detail: 'bounded_retry_exhausted');
      return;
    }
    final backoffIndex = min(retryCount - 1, config.backoffMs.length - 1);
    final nextAttempt = nowMs + config.backoffMs[backoffIndex];
    await responses.markRetry(
      responseId,
      nextAttemptAtMs: nextAttempt,
      error: 'no eligible return peer',
    );
    await _progress(
      AuthorityResponseProgress(
        responseId: responseId,
        state: 'MESH_QUEUED',
        routeMode: ReturnRouteMode.retry.name,
        returnHops: envelope.hopCount,
        retryCount: retryCount,
        error: 'no_eligible_return_route',
      ),
    );
    _metric('reverse_route_miss', detail: 'durable_retry');
  }

  Future<void> _expireResponse(
    String responseId, {
    required String detail,
  }) async {
    await responses.markExpired(responseId);
    await _progress(
      AuthorityResponseProgress(
        responseId: responseId,
        state: 'EXPIRED',
        error: detail,
      ),
    );
  }

  Future<void> _failResponse(String responseId, String detail) async {
    await responses.markFailed(responseId, detail);
    await _progress(
      AuthorityResponseProgress(
        responseId: responseId,
        state: 'FAILED',
        error: detail,
      ),
    );
  }

  Future<void> _progress(AuthorityResponseProgress progress) async {
    _metric('response_progress_reported', detail: progress.state);
    final callback = onProgress;
    if (callback == null) return;
    try {
      await callback(progress);
    } catch (_) {
      // Telemetry cannot interrupt cryptographic delivery or retry handling.
      _metric('response_progress_callback_failed');
    }
  }

  Future<bool> _sendRoute(MeshEnvelope envelope, ReverseRoute route) async {
    if (await _sendNextHop(envelope, route.previousPeerEphemeralId)) {
      return true;
    }
    final hint = route.previousPeerHint;
    final connector = connectToPeerHint;
    if (hint == null || hint.isEmpty || connector == null) return false;
    try {
      _metric('reverse_route_reconnect_started');
      await connector(hint, route.previousPeerEphemeralId);
      final sent = await _sendNextHop(envelope, route.previousPeerEphemeralId);
      _metric(
        sent
            ? 'reverse_route_reconnect_succeeded'
            : 'reverse_route_reconnect_unavailable',
      );
      return sent;
    } catch (_) {
      _metric('reverse_route_reconnect_failed');
      return false;
    }
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
