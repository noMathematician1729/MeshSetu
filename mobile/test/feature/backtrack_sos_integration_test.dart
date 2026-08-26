import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshsetu_mobile/core/ble/gatt_server.dart';
import 'package:meshsetu_mobile/core/ble/mesh_transport.dart';
import 'package:meshsetu_mobile/core/ble/return_router.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/return_channel_dao.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/core/protocol/authority_signature.dart';
import 'package:meshsetu_mobile/core/protocol/relay_engine.dart';
import 'package:meshsetu_mobile/core/protocol/return_protocol.dart';
import 'package:meshsetu_mobile/core/protocol/secure_envelope.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_bridge.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_downlink_poller.dart';
import 'package:test/test.dart';

class _NoopStore extends RelayStore {
  @override
  void persist(MeshEnvelope envelope, {Uint8List? encryptedBytes}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'hands a gateway command to a verified sender and reports delivery only after its receipt',
    () async {
      // This test models two independent devices, each with its own in-memory
      // executor. Drift's process-wide guard cannot distinguish that valid
      // topology from two instances sharing one executor, so suppress it only
      // for this test and restore the global setting during teardown.
      final previousDatabaseWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousDatabaseWarningSetting,
      );
      final vector =
          jsonDecode(
                File('test/fixtures/authority_vectors.json').readAsStringSync(),
              )
              as Map<String, Object?>;
      final signed = ReturnProtocol.decodeSigned(
        Uint8List.fromList(base64Decode(vector['signedB64']! as String)),
      );
      final body = signed.body;
      final trust = AuthorityTrustSnapshot(
        siteId: body.siteId,
        keyId: vector['keyId']! as String,
        publicKey: AuthorityPublicKeyJwk.fromJson(
          Map<String, Object?>.from(vector['publicKeyJwk']! as Map),
        ).toEcPublicKey(),
      );
      final gatewayDatabase = MeshDatabase.forTesting(NativeDatabase.memory());
      final senderDatabase = MeshDatabase.forTesting(NativeDatabase.memory());
      final injected = Completer<MeshEnvelope>();
      var commandServed = false;
      var gatewayAcknowledged = false;
      final receiptUploads = <Map<String, Object?>>[];
      final bridge = GatewayBridge(
        baseUrl: Uri.parse('https://control.test'),
        demoKey: 'gateway-key',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            if (!commandServed) {
              commandServed = true;
              return http.Response(
                jsonEncode({
                  'cursor': '${body.createdAtMs}:${body.responseId}',
                  'commands': [
                    {
                      'response_id': body.responseId,
                      'event_id': body.replyToEventId,
                      'site_id': body.siteId,
                      'destination_ephemeral_id': body.destinationEphemeralId
                          .toString(),
                      'signed_payload_b64': vector['signedB64'],
                      'created_at_ms': body.createdAtMs,
                      'expires_at_ms': body.expiresAtMs,
                    },
                  ],
                }),
                200,
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 25));
            return http.Response(
              jsonEncode({
                'cursor': '${body.createdAtMs}:${body.responseId}',
                'commands': [],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/received')) {
            gatewayAcknowledged = true;
            return http.Response('{"ok":true}', 200);
          }
          if (request.url.path.endsWith('/receipts')) {
            receiptUploads.add(
              Map<String, Object?>.from(
                jsonDecode(request.body) as Map<String, dynamic>,
              ),
            );
            return http.Response('{"ok":true}', 200);
          }
          return http.Response('not found', 404);
        }),
      );
      final poller = GatewayDownlinkPoller(
        bridge: bridge,
        database: gatewayDatabase,
        siteId: body.siteId,
        gatewaySessionId: 'gateway-session',
        localEphemeralId: 700,
        clockMs: () => 100,
        submitToMesh: (envelope) async => injected.complete(envelope),
      );
      final transport = MeshTransportCoordinator(
        server: MeshGattServer(),
        relay: MeshRelayEngine(
          siteId: body.siteId,
          crypto: AeadEnvelope(List.filled(32, 4)),
          store: _NoopStore(),
          clockMs: () => 100,
        ),
      );
      addTearDown(() async {
        await poller.dispose();
        await transport.stop();
        await gatewayDatabase.close();
        await senderDatabase.close();
      });

      poller.start();
      final envelope = await injected.future.timeout(
        const Duration(seconds: 2),
      );
      final queued = await AuthorityResponseRepository(
        gatewayDatabase,
      ).get(body.responseId);
      expect(gatewayAcknowledged, isTrue);
      expect(queued?.state, 'READY');
      expect(
        receiptUploads,
        isEmpty,
        reason: 'gateway custody is not sender delivery',
      );

      final sender = ReturnRouter(
        transport: transport,
        routes: ReverseRouteRepository(senderDatabase, clockMs: () => 100),
        responses: AuthorityResponseRepository(
          senderDatabase,
          clockMs: () => 100,
        ),
        localEphemeralId: body.destinationEphemeralId,
        trustSnapshot: () async => trust,
        isKnownSosEvent: (eventId) async => eventId == body.replyToEventId,
        clockMs: () => 100,
      );
      await sender.handleResponderUpdate(
        envelope: envelope,
        fromPeerId: 'gateway-peer',
        encryptedBytes: Uint8List.fromList([1]),
      );

      final receipt = await (senderDatabase.select(
        senderDatabase.responseReceipts,
      )).getSingle();
      expect(
        await (senderDatabase.select(senderDatabase.authorityInbox)).get(),
        hasLength(1),
      );
      expect(
        receiptUploads,
        isEmpty,
        reason: 'the mesh receipt has not reached the gateway yet',
      );

      await poller.handleReceipt(
        AckMessageData(
          ackId: receipt.receiptId,
          kind: AckKind.responseDelivered,
          ackedObjectId: envelope.objectId,
          responseId: receipt.responseId,
          replyToEventId: receipt.replyToEventId,
          senderEphemeralId: receipt.senderEphemeralId,
          createdAtMs: receipt.createdAtMs,
          expiresAtMs: body.expiresAtMs,
        ),
      );

      expect(receiptUploads, hasLength(1));
      expect(receiptUploads.single, {
        'receipt_id': '${body.responseId}:${body.destinationEphemeralId}',
        'reply_to_event_id': body.replyToEventId,
        'sender_ephemeral_id': body.destinationEphemeralId.toString(),
        'created_at_ms': 100,
      });
      expect(
        await (gatewayDatabase.select(
          gatewayDatabase.responseReceipts,
        )).getSingle(),
        isA<ResponseReceipt>().having(
          (value) => value.state,
          'state',
          'UPLOADED',
        ),
      );
    },
  );
}
