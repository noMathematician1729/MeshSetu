import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/return_channel_dao.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/core/protocol/return_protocol.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_bridge.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_downlink_poller.dart';

void main() {
  late Map<String, Object?> vector;
  late SignedResponderUpdateData signed;
  late MeshDatabase database;

  setUpAll(() {
    vector =
        jsonDecode(
              File('test/fixtures/authority_vectors.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    signed = ReturnProtocol.decodeSigned(
      base64Decode(vector['signedB64']! as String),
    );
  });

  setUp(() {
    database = MeshDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('persists a polled command before injecting it into the mesh', () async {
    var commandReturned = false;
    var acknowledged = false;
    final injected = Completer<MeshEnvelope>();
    final bridge = GatewayBridge(
      baseUrl: Uri.parse('https://control.test'),
      demoKey: 'gateway-key',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          if (commandReturned) {
            return http.Response(
              jsonEncode({'cursor': '100', 'commands': []}),
              200,
            );
          }
          commandReturned = true;
          return http.Response(
            jsonEncode({
              'cursor': '100',
              'commands': [
                {
                  'response_id': signed.body.responseId,
                  'event_id': signed.body.replyToEventId,
                  'site_id': signed.body.siteId,
                  'destination_ephemeral_id': signed.body.destinationEphemeralId
                      .toString(),
                  'signed_payload_b64': vector['signedB64'],
                  'created_at_ms': signed.body.createdAtMs,
                  'expires_at_ms': signed.body.expiresAtMs,
                },
              ],
            }),
            200,
          );
        }
        acknowledged = true;
        return http.Response('{"ok":true}', 200);
      }),
    );
    final poller = GatewayDownlinkPoller(
      bridge: bridge,
      database: database,
      siteId: signed.body.siteId,
      gatewaySessionId: 'gateway-session',
      localEphemeralId: 700,
      clockMs: () => 100,
      submitToMesh: (envelope) async {
        injected.complete(envelope);
      },
    );
    poller.start();

    final envelope = await injected.future.timeout(const Duration(seconds: 2));
    final stored = await AuthorityResponseRepository(
      database,
    ).get(signed.body.responseId);
    expect(stored?.state, 'READY');
    expect(stored?.meshObjectId, envelope.objectId);
    expect(envelope.payloadType.name, 'responderUpdate');
    expect(acknowledged, isTrue);
    await poller.dispose();
  });

  test(
    'uploads durable receipts and marks them uploaded only after HTTP success',
    () async {
      var uploads = 0;
      final bridge = GatewayBridge(
        baseUrl: Uri.parse('https://control.test'),
        demoKey: 'gateway-key',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/receipts')) uploads++;
          return http.Response('{"ok":true}', 200);
        }),
      );
      await AuthorityResponseRepository(database).enqueueReceipt(
        ResponseReceiptsCompanion.insert(
          receiptId: 'response-vector-1:123456789',
          responseId: signed.body.responseId,
          replyToEventId: signed.body.replyToEventId,
          senderEphemeralId: signed.body.destinationEphemeralId,
          createdAtMs: signed.body.createdAtMs,
        ),
      );
      final poller = GatewayDownlinkPoller(
        bridge: bridge,
        database: database,
        siteId: signed.body.siteId,
        gatewaySessionId: 'gateway-session',
        localEphemeralId: 700,
        clockMs: () => 100,
        submitToMesh: (_) async {},
      );
      poller.start();
      await poller.uploadReadyReceipts();

      final receipt = await (database.select(
        database.responseReceipts,
      )).getSingle();
      expect(uploads, 1);
      expect(receipt.state, 'UPLOADED');
      await poller.dispose();
    },
  );
}
