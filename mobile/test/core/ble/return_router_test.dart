import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:test/test.dart';
import 'package:meshsetu_mobile/core/ble/gatt_peer_session.dart';
import 'package:meshsetu_mobile/core/ble/gatt_server.dart';
import 'package:meshsetu_mobile/core/ble/mesh_transport.dart';
import 'package:meshsetu_mobile/core/ble/return_router.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/return_channel_dao.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/core/protocol/authority_signature.dart';
import 'package:meshsetu_mobile/core/protocol/frame.dart';
import 'package:meshsetu_mobile/core/protocol/relay_engine.dart';
import 'package:meshsetu_mobile/core/protocol/return_protocol.dart';
import 'package:meshsetu_mobile/core/protocol/secure_envelope.dart';

class _FakeLink implements PeerLink {
  _FakeLink({this.sendSucceeds = true});

  final bool sendSucceeds;
  @override
  int get mtu => 185;
  final sentFrames = <Uint8List>[];
  final _incoming = StreamController<Uint8List>.broadcast();
  final _state = StreamController<PeerSessionState>.broadcast();

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Stream<PeerSessionState> get state => _state.stream;

  @override
  Future<bool> send(Uint8List bytes, {bool withResponse = true}) async {
    sentFrames.add(Uint8List.fromList(bytes));
    return sendSucceeds;
  }

  @override
  Future<void> close() async {
    await _incoming.close();
    await _state.close();
  }
}

class _Store extends RelayStore {
  @override
  void persist(MeshEnvelope envelope, {Uint8List? encryptedBytes}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, Object?> vector;
  late SignedResponderUpdateData signed;
  late AuthorityTrustSnapshot trust;

  setUpAll(() {
    vector =
        jsonDecode(
              File('test/fixtures/authority_vectors.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    signed = ReturnProtocol.decodeSigned(
      Uint8List.fromList(base64Decode(vector['signedB64']! as String)),
    );
    final jwk = AuthorityPublicKeyJwk.fromJson(
      Map<String, Object?>.from(vector['publicKeyJwk']! as Map),
    );
    trust = AuthorityTrustSnapshot(
      siteId: signed.body.siteId,
      keyId: vector['keyId']! as String,
      publicKey: jwk.toEcPublicKey(),
    );
  });

  MeshDatabase database() => MeshDatabase.forTesting(NativeDatabase.memory());

  MeshTransportCoordinator transport({
    void Function(List<RelayMetric>)? onMetrics,
  }) => MeshTransportCoordinator(
    server: MeshGattServer(),
    relay: MeshRelayEngine(
      siteId: signed.body.siteId,
      crypto: AeadEnvelope(List.filled(32, 4)),
      store: _Store(),
      clockMs: () => 100,
    ),
    onMetrics: onMetrics,
  );

  MeshEnvelope responseEnvelope({
    Uint8List? payload,
    String? siteId,
    int hopCount = 0,
    int hopLimit = 6,
    int objectId = 7001,
  }) => MeshEnvelope(
    objectId: objectId,
    eventId: signed.body.replyToEventId,
    siteId: siteId ?? signed.body.siteId,
    roomId: '',
    createdAtMs: signed.body.createdAtMs,
    expiresAtMs: signed.body.expiresAtMs,
    hopCount: hopCount,
    hopLimit: hopLimit,
    priority: PriorityBand.p1High,
    payloadType: PayloadType.responderUpdate,
    payload:
        payload ??
        Uint8List.fromList(base64Decode(vector['signedB64']! as String)),
    originEphemeralId: 900,
    traceId: signed.body.originalTraceId,
  );

  Future<ReturnRouter> buildRouter(
    MeshDatabase db,
    MeshTransportCoordinator coordinator, {
    int localEphemeralId = 999,
    Future<AuthorityTrustSnapshot?> Function()? trustSnapshot,
    Future<bool> Function(String eventId)? isKnown,
    void Function(String kind, {String? detail, int? value})? onMetric,
    VerifiedResponseListener? onVerifiedResponse,
    AuthorityResponseProgressListener? onProgress,
    PeerHintConnector? connectToPeerHint,
  }) async {
    return ReturnRouter(
      transport: coordinator,
      routes: ReverseRouteRepository(db, clockMs: () => 100),
      responses: AuthorityResponseRepository(db, clockMs: () => 100),
      localEphemeralId: localEphemeralId,
      trustSnapshot: trustSnapshot ?? (() async => trust),
      isKnownSosEvent: isKnown ?? ((_) async => true),
      onVerifiedResponse: onVerifiedResponse,
      onMetric: onMetric,
      onProgress: onProgress,
      connectToPeerHint: connectToPeerHint,
      clockMs: () => 100,
    );
  }

  Future<void> registerPeer(
    MeshTransportCoordinator coordinator,
    String peerId,
    int ephemeralId,
    _FakeLink link,
  ) async {
    coordinator.attach(peerId, link, siteFingerprint: 1);
    coordinator.peerDirectory.register(
      ephemeralNodeId: ephemeralId,
      peerId: peerId,
      mtu: link.mtu,
      lastSeenMs: 100,
      siteFingerprint: 1,
    );
  }

  Future<void> learnRoute(
    ReverseRouteRepository routes,
    int peerEphemeralId, {
    String? eventId,
    String? previousPeerHint,
  }) => routes.observeValidSos(
    envelope: MeshEnvelope(
      objectId: 8000 + peerEphemeralId,
      eventId: eventId ?? signed.body.replyToEventId,
      siteId: signed.body.siteId,
      roomId: 'public',
      createdAtMs: 1,
      expiresAtMs: signed.body.expiresAtMs,
      hopCount: 1,
      hopLimit: 6,
      priority: PriorityBand.p0Critical,
      payloadType: PayloadType.structuredSos,
      payload: Uint8List.fromList([1]),
      originEphemeralId: signed.body.destinationEphemeralId,
    ),
    previousPeerEphemeralId: peerEphemeralId,
    previousPeerHint: previousPeerHint,
  );

  test(
    'forwards through the freshest reverse route and persists state',
    () async {
      final db = database();
      final coordinator = transport();
      final link = _FakeLink();
      await registerPeer(coordinator, 'route-peer', 700, link);
      final routes = ReverseRouteRepository(db, clockMs: () => 100);
      await learnRoute(routes, 700);
      final router = await routerFor(db, coordinator, routes: routes);

      await router.handleResponderUpdate(
        envelope: responseEnvelope(),
        fromPeerId: 'ingress-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      final row = await AuthorityResponseRepository(
        db,
      ).get(signed.body.responseId);
      expect(row?.state, 'FORWARDING');
      expect(row?.routeMode, ReturnRouteMode.reverseCache.name);
      expect(link.sentFrames, isNotEmpty);
      expect(
        link.sentFrames.every(
          (frame) => FrameCodec.decode(frame).type == FrameType.data,
        ),
        isTrue,
      );
      await coordinator.stop();
      await db.close();
    },
  );

  test('tries an alternate reverse route after the first send fails', () async {
    final db = database();
    final metrics = <String>[];
    final coordinator = transport(onMetrics: (_) {});
    final broken = _FakeLink(sendSucceeds: false);
    final healthy = _FakeLink();
    await registerPeer(coordinator, 'broken-peer', 701, broken);
    await registerPeer(coordinator, 'healthy-peer', 702, healthy);
    final routes = ReverseRouteRepository(db, clockMs: () => 100);
    await learnRoute(routes, 701);
    await learnRoute(routes, 702);
    final router = ReturnRouter(
      transport: coordinator,
      routes: routes,
      responses: AuthorityResponseRepository(db, clockMs: () => 100),
      localEphemeralId: 999,
      trustSnapshot: () async => trust,
      isKnownSosEvent: (_) async => true,
      clockMs: () => 100,
      onMetric: (kind, {detail, value}) => metrics.add(kind),
    );

    await router.handleResponderUpdate(
      envelope: responseEnvelope(objectId: 7002),
      fromPeerId: 'ingress-peer',
      encryptedBytes: Uint8List.fromList([1]),
    );

    final row = await AuthorityResponseRepository(
      db,
    ).get(signed.body.responseId);
    expect(row?.state, 'FORWARDING');
    expect(row?.routeMode, ReturnRouteMode.alternateCache.name);
    expect(broken.sentFrames, isNotEmpty);
    expect(healthy.sentFrames, isNotEmpty);
    expect(metrics, contains('response_forwarded'));
    await coordinator.stop();
    await db.close();
  });

  test(
    'uses bounded fallback peers when no reverse route is available',
    () async {
      final db = database();
      final metrics = <String>[];
      final coordinator = transport();
      final fallback = _FakeLink();
      await registerPeer(coordinator, 'fallback-peer', 703, fallback);
      final router = await buildRouter(
        db,
        coordinator,
        onMetric: (kind, {detail, value}) => metrics.add(kind),
      );

      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7003),
        fromPeerId: 'ingress-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      final row = await AuthorityResponseRepository(
        db,
      ).get(signed.body.responseId);
      expect(row?.state, 'FORWARDING');
      expect(row?.routeMode, ReturnRouteMode.fallback.name);
      expect(fallback.sentFrames, isNotEmpty);
      expect(metrics, contains('fallback_forwarded'));
      await coordinator.stop();
      await db.close();
    },
  );

  test(
    'verifies sender delivery, persists a receipt, and deduplicates replay',
    () async {
      final db = database();
      final coordinator = transport();
      final delivered = <String>[];
      final router = await buildRouter(
        db,
        coordinator,
        localEphemeralId: signed.body.destinationEphemeralId,
        onVerifiedResponse: (body) async => delivered.add(body.messageText),
      );
      final envelope = responseEnvelope(objectId: 7004);

      await router.handleResponderUpdate(
        envelope: envelope,
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );
      await router.handleResponderUpdate(
        envelope: envelope,
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      final inbox = await (db.select(db.authorityInbox)).get();
      final receipts = await (db.select(db.responseReceipts)).get();
      expect(delivered, [signed.body.messageText]);
      expect(inbox, hasLength(1));
      expect(receipts, hasLength(1));
      await coordinator.stop();
      await db.close();
    },
  );

  test(
    'routes an injected gateway response through local verification and receipt progress',
    () async {
      final db = database();
      final coordinator = transport();
      final progress = <AuthorityResponseProgress>[];
      final router = await buildRouter(
        db,
        coordinator,
        localEphemeralId: signed.body.destinationEphemeralId,
        onProgress: progress.add,
      );

      await router.handleInjectedResponderUpdate(
        responseEnvelope(objectId: 7008),
      );

      expect(
        progress.map((event) => event.state),
        contains('SENDER_DELIVERED'),
      );
      expect(
        progress
            .singleWhere((event) => event.state == 'SENDER_DELIVERED')
            .receiptId,
        '${signed.body.responseId}:${signed.body.destinationEphemeralId}',
      );
      expect(await (db.select(db.authorityInbox)).get(), hasLength(1));
      expect(await (db.select(db.responseReceipts)).get(), hasLength(1));
      await coordinator.stop();
      await db.close();
    },
  );

  test(
    'uses a destination-scoped reverse route when incident IDs converged',
    () async {
      final db = database();
      final coordinator = transport();
      final link = _FakeLink();
      await registerPeer(coordinator, 'sender-peer', 704, link);
      final routes = ReverseRouteRepository(db, clockMs: () => 100);
      await learnRoute(routes, 704, eventId: 'wire-event-before-convergence');
      final router = await routerFor(db, coordinator, routes: routes);
      final original = responseEnvelope(objectId: 7010);
      final converged = MeshEnvelope(
        objectId: original.objectId,
        eventId: 'dashboard-incident-id',
        siteId: original.siteId,
        roomId: original.roomId,
        createdAtMs: original.createdAtMs,
        expiresAtMs: original.expiresAtMs,
        hopCount: original.hopCount,
        hopLimit: original.hopLimit,
        priority: original.priority,
        payloadType: original.payloadType,
        payload: original.payload,
        originEphemeralId: original.originEphemeralId,
        traceId: original.traceId,
      );

      await router.handleResponderUpdate(
        envelope: converged,
        fromPeerId: 'gateway-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      expect(link.sentFrames, isNotEmpty);
      expect(
        (await AuthorityResponseRepository(
          db,
        ).get(signed.body.responseId))?.state,
        'FORWARDING',
      );
      await coordinator.stop();
      await db.close();
    },
  );

  test(
    'reconnects through a persisted peer hint before retrying a reverse route',
    () async {
      final db = database();
      final coordinator = transport();
      final routes = ReverseRouteRepository(db, clockMs: () => 100);
      await learnRoute(routes, 705, previousPeerHint: 'sender-device');
      final link = _FakeLink();
      final reconnects = <String>[];
      final router = await buildRouter(
        db,
        coordinator,
        connectToPeerHint: (hint, expectedEphemeralId) async {
          reconnects.add(hint);
          await registerPeer(coordinator, hint, expectedEphemeralId, link);
        },
      );

      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7011),
        fromPeerId: 'gateway-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      expect(reconnects, ['sender-device']);
      expect(link.sentFrames, isNotEmpty);
      expect(
        (await AuthorityResponseRepository(
          db,
        ).get(signed.body.responseId))?.routeMode,
        ReturnRouteMode.reverseCache.name,
      );
      await coordinator.stop();
      await db.close();
    },
  );

  test('reports no-route as queued retry rather than forwarding', () async {
    final db = database();
    final coordinator = transport();
    final progress = <AuthorityResponseProgress>[];
    final router = await buildRouter(db, coordinator, onProgress: progress.add);

    await router.handleResponderUpdate(
      envelope: responseEnvelope(objectId: 7012),
      fromPeerId: 'gateway-peer',
      encryptedBytes: Uint8List.fromList([1]),
    );

    expect(progress, hasLength(1));
    expect(progress.single.state, 'MESH_QUEUED');
    expect(progress.single.routeMode, ReturnRouteMode.retry.name);
    expect(progress.single.error, 'no_eligible_return_route');
    expect(
      (await AuthorityResponseRepository(
        db,
      ).get(signed.body.responseId))?.state,
      'RETRY',
    );
    await coordinator.stop();
    await db.close();
  });

  test('reports bounded no-route retry and terminal failure', () async {
    final db = database();
    final coordinator = transport();
    final progress = <AuthorityResponseProgress>[];
    final router = ReturnRouter(
      transport: coordinator,
      routes: ReverseRouteRepository(db, clockMs: () => 100),
      responses: AuthorityResponseRepository(db, clockMs: () => 100),
      localEphemeralId: 999,
      trustSnapshot: () async => trust,
      isKnownSosEvent: (_) async => true,
      config: const ReturnChannelConfig(backoffMs: [0, 0, 0, 0]),
      clockMs: () => 100,
      onProgress: progress.add,
    );

    await router.handleResponderUpdate(
      envelope: responseEnvelope(objectId: 7009),
      fromPeerId: 'ingress-peer',
      encryptedBytes: Uint8List.fromList([1]),
    );
    for (var attempt = 0; attempt < 3; attempt++) {
      await router.retryDue();
    }

    expect(progress.map((event) => event.routeMode), contains('retry'));
    expect(progress.last.state, 'FAILED');
    expect(progress.last.error, 'no_eligible_return_route');
    expect(
      (await AuthorityResponseRepository(
        db,
      ).get(signed.body.responseId))?.state,
      'FAILED',
    );
    await coordinator.stop();
    await db.close();
  });

  test(
    'reports the authority site guard without logging key material',
    () async {
      final db = database();
      final metrics = <String>[];
      final coordinator = transport();
      final mismatchedTrust = AuthorityTrustSnapshot(
        siteId: 'another-event-site',
        keyId: trust.keyId,
        publicKey: trust.publicKey,
      );
      final router = await buildRouter(
        db,
        coordinator,
        localEphemeralId: signed.body.destinationEphemeralId,
        trustSnapshot: () async => mismatchedTrust,
        onMetric: (kind, {detail, value}) =>
            metrics.add('$kind${detail == null ? '' : ':$detail'}'),
      );

      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7013),
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      expect(
        metrics,
        contains('authority_signature_rejected:authority_trust_rejected_site'),
      );
      await coordinator.stop();
      await db.close();
    },
  );

  test(
    'rejects tampered signatures, wrong site, unknown events, and hop limit',
    () async {
      final db = database();
      final metrics = <String>[];
      final coordinator = transport();
      final router = await buildRouter(
        db,
        coordinator,
        localEphemeralId: signed.body.destinationEphemeralId,
        isKnown: (_) async => false,
        onMetric: (kind, {detail, value}) => metrics.add(kind),
      );
      final tampered = Uint8List.fromList(
        base64Decode(vector['signedB64']! as String),
      )..[20] ^= 1;

      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7005, payload: tampered),
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );
      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7006, siteId: 'wrong-site'),
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );
      await router.handleResponderUpdate(
        envelope: responseEnvelope(objectId: 7007, hopCount: 6, hopLimit: 6),
        fromPeerId: 'relay-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      expect(await (db.select(db.authorityInbox)).get(), isEmpty);
      expect(metrics, contains('authority_signature_rejected'));
      expect(metrics, contains('response_expired'));
      await coordinator.stop();
      await db.close();
    },
  );
}

// Helpers kept below the tests to make the route assertions read like the
// protocol state machine rather than a protobuf/frame implementation detail.
Future<ReturnRouter> routerFor(
  MeshDatabase db,
  MeshTransportCoordinator coordinator, {
  required ReverseRouteRepository routes,
}) async => ReturnRouter(
  transport: coordinator,
  routes: routes,
  responses: AuthorityResponseRepository(db, clockMs: () => 100),
  localEphemeralId: 999,
  trustSnapshot: () async => throw StateError('not used'),
  isKnownSosEvent: (_) async => true,
  clockMs: () => 100,
);
