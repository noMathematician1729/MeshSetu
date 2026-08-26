import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshsetu_mobile/app/mesh_bridge.dart';
import 'package:meshsetu_mobile/app/mesh_bridge_client.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_bridge.dart';
import 'package:meshsetu_mobile/feature/sos/sos_payload.dart';
import 'package:test/test.dart';

const _sos = StructuredSosPayload(
  incidentType: 'medical',
  transcript: 'need help',
  sttConfidence: 1,
  triagePriority: PriorityBand.p0Critical,
  triageConfidence: 1,
  hazards: ['medical'],
  rationale: [],
  inputMode: InputMode.tap,
  latitude: 19.076,
  longitude: 72.8777,
  accuracyM: 8.5,
  locationCapturedAtMs: 42,
  reporter: SosReporter(
    reporterUid: 'aabbccddeeff',
    name: 'Asha Patel',
    phone: '+919876543210',
    language: 'English',
    bloodGroup: 'O+',
    primaryContactName: 'Ravi Patel',
    primaryContactPhone: '+919876543211',
  ),
);

MeshEnvelope _envelope({required int objectId, required String eventId}) =>
    MeshEnvelope(
      objectId: objectId,
      eventId: eventId,
      siteId: 'demo-site',
      roomId: 'public',
      createdAtMs: 1,
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 600000,
      hopCount: 0,
      hopLimit: 4,
      priority: PriorityBand.p0Critical,
      payloadType: PayloadType.structuredSos,
      payload: _sos.encode(),
      originEphemeralId: 7,
      traceId: Uint8List(16),
    );

Future<void> _insertFinalizedSos(
  MeshDatabase db, {
  required String eventId,
  required int objectId,
  String state = 'relaying',
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return db
      .into(db.outboxEvents)
      .insert(
        OutboxEventsCompanion.insert(
          eventId: eventId,
          objectId: Value(objectId),
          siteId: 'demo-site',
          roomId: 'public',
          payloadType: PayloadType.structuredSos.name,
          priority: PriorityBand.p0Critical.name,
          payload: Value(_sos.encode()),
          state: Value(state),
          createdAtMs: now,
          updatedAtMs: now,
          expiresAtMs: now + 600000,
        ),
      );
}

void main() {
  late MeshDatabase database;
  late MeshBridgeClient client;

  setUp(() {
    database = MeshDatabase.forTesting(NativeDatabase.memory());
    client = MeshBridgeClient(
      database,
      registerTaskDataCallback: false,
      syncRelayInbox: false,
    );
  });

  tearDown(() async {
    await client.dispose();
    await database.close();
  });

  test(
    'an SOS submitted before the gateway is attached is uploaded once it is',
    () async {
      final paths = <String>[];
      final bridge = GatewayBridge(
        baseUrl: Uri.parse('https://control.test'),
        demoKey: 'change-me',
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response('{"ok":true}', 200);
        }),
      );
      await _insertFinalizedSos(database, eventId: 'evt-1', objectId: 4242);

      // The foreground task reports the submission while no admin route is
      // configured yet: this must be queued, not dropped.
      client.handleTaskData({
        'status': 'mesh_origin_submitted',
        'envelope': MeshBridge.envelopeToJson(
          _envelope(objectId: 4242, eventId: 'evt-1'),
        ),
        'encryptedBytes': base64Encode(const [1, 2, 3, 4]),
      });
      await Future<void>.delayed(Duration.zero);
      expect(paths, isEmpty);

      client.gatewayBridge = bridge;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(paths, contains('/v1/gateway/objects'));
    },
  );

  test(
    'a rejected encrypted packet still reaches the control room as plaintext',
    () async {
      final paths = <String>[];
      final bridge = GatewayBridge(
        baseUrl: Uri.parse('https://control.test'),
        demoKey: 'change-me',
        client: MockClient((request) async {
          paths.add(request.url.path);
          // The verified route rejects the packet (e.g. undecryptable);
          // delivery must not stop there.
          if (request.url.path == '/v1/gateway/objects') {
            return http.Response('{"error":"packet rejected"}', 422);
          }
          return http.Response('{"ok":true}', 200);
        }),
      );
      await _insertFinalizedSos(database, eventId: 'evt-2', objectId: 99);

      client.gatewayBridge = bridge;
      client.handleTaskData({
        'status': 'mesh_origin_submitted',
        'envelope': MeshBridge.envelopeToJson(
          _envelope(objectId: 99, eventId: 'evt-2'),
        ),
        'encryptedBytes': base64Encode(const [9, 9]),
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(paths, contains('/v1/gateway/objects'));
      expect(paths, contains('/v1/gateway/relay-sos'));
    },
  );

  test(
    'a queued SOS with no mesh peer is delivered from the durable outbox',
    () async {
      final bodies = <Map<String, Object?>>[];
      final bridge = GatewayBridge(
        baseUrl: Uri.parse('https://control.test'),
        demoKey: 'change-me',
        client: MockClient((request) async {
          bodies.add(jsonDecode(request.body) as Map<String, Object?>);
          return http.Response('{"ok":true}', 200);
        }),
      );
      // No 'mesh_origin_submitted' ever arrives: event mode was not running
      // when this SOS was written, so there is no encrypted packet and no
      // peer took custody. Admin delivery must still happen.
      await _insertFinalizedSos(
        database,
        eventId: 'evt-3',
        objectId: 7,
        state: 'ready',
      );

      client.gatewayBridge = bridge;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bodies, hasLength(1));
      expect(bodies.single['relay_device_id'], 'gateway');
      final event = (bodies.single['event'] as Map).cast<String, Object?>();
      expect(event['event_id'], 'evt-3');
      expect(event['incident_type'], 'medical');
      expect(event['latitude'], 19.076);
      expect(event['reporter_uid'], 'aabbccddeeff');
    },
  );

  test('a delivered SOS is not uploaded again on the next attempt', () async {
    var relayPosts = 0;
    final bridge = GatewayBridge(
      baseUrl: Uri.parse('https://control.test'),
      demoKey: 'change-me',
      client: MockClient((request) async {
        if (request.url.path == '/v1/gateway/relay-sos') relayPosts++;
        return http.Response('{"ok":true}', 200);
      }),
    );
    await _insertFinalizedSos(database, eventId: 'evt-4', objectId: 11);

    client.gatewayBridge = bridge;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    client.gatewayBridge = bridge;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(relayPosts, 1);
  });
}
