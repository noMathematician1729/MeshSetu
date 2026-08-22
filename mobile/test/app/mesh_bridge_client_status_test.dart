import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';
import 'package:meshsetu_mobile/app/mesh_bridge_client.dart';
import 'package:meshsetu_mobile/app/sos_delivery.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/feature/rooms/room_policy.dart';
import 'package:meshsetu_mobile/feature/rooms/room_repository.dart';

void main() {
  late MeshDatabase database;
  late MeshBridgeClient client;

  setUp(() {
    database = MeshDatabase.forTesting(NativeDatabase.memory());
    client = MeshBridgeClient(database);
  });

  tearDown(() async {
    await client.dispose();
    await database.close();
  });

  test(
    'projects foreground task lifecycle and peer snapshots into MeshStatus',
    () async {
      expect(client.meshStatus, MeshStatus.stopped);
      final statuses = <MeshStatus>[];
      final subscription = client.meshStatusStream.listen(statuses.add);
      addTearDown(subscription.cancel);

      client.handleTaskData(const {'status': 'started'});
      client.handleTaskData(const {
        'status': 'mesh_status',
        'value': 'advertising',
      });
      client.handleTaskData({
        'status': 'mesh_peers',
        'peers': [
          {'peerId': 'connected', 'connected': true},
          {'peerId': 'disconnected', 'connected': false},
          {'peerId': 'legacy-without-flag'},
        ],
      });
      await Future<void>.delayed(Duration.zero);

      expect(client.meshStatus.eventModeRunning, isTrue);
      expect(client.meshStatus.statusText, 'advertising');
      // One explicit connected peer plus one legacy peer that does not report
      // a connected flag yet; explicitly disconnected peers are excluded.
      expect(client.meshStatus.peerCount, 2);
      expect(statuses, hasLength(3));

      client.handleTaskData(const {'status': 'stopped'});
      await Future<void>.delayed(Duration.zero);
      expect(client.meshStatus, MeshStatus.stopped);
      expect(statuses.last, MeshStatus.stopped);
    },
  );

  test(
    'room-prepared bridge drains ready messages after foreground identity arrives',
    () async {
      final submitted = Completer<MeshEnvelope>();
      await client.dispose();
      client = MeshBridgeClient(
        database,
        registerTaskDataCallback: false,
        syncRelayInbox: false,
        sendToMesh: (envelope) async {
          if (!submitted.isCompleted) submitted.complete(envelope);
        },
      );
      final repository = RoomRepository(database, siteId: 'participant-site');

      client.prepareForSite(siteId: 'participant-site');
      final eventId = await repository.sendMessage(
        policy: policyForRole('public', 'public'),
        userRoles: const {'public'},
        text: 'participant offline message',
      );
      client.handleTaskData(const {
        'status': 'started',
        'localEphemeralId': 17,
      });

      final envelope = await submitted.future.timeout(
        const Duration(seconds: 1),
      );
      expect(envelope.siteId, 'participant-site');
      expect(envelope.originEphemeralId, 17);
      expect(envelope.eventId, eventId);
      expect(envelope.payloadType, PayloadType.roomMessage);
    },
  );

  test(
    'ignores malformed mesh-status and peer payloads without changing state',
    () async {
      client.handleTaskData(const {'status': 'started'});
      await Future<void>.delayed(Duration.zero);
      final before = client.meshStatus;

      client.handleTaskData(const {'status': 'mesh_status', 'value': 4});
      client.handleTaskData(const {'status': 'mesh_peers', 'peers': 'invalid'});
      client.handleTaskData('not-a-map');
      await Future<void>.delayed(Duration.zero);

      expect(client.meshStatus.eventModeRunning, before.eventModeRunning);
      expect(client.meshStatus.peerCount, before.peerCount);
      expect(client.meshStatus.statusText, before.statusText);
    },
  );

  test(
    'reportBlockedReason surfaces a preflight failure and clears on started',
    () {
      expect(client.meshStatus.blockedReason, isNull);

      client.reportBlockedReason('Turn on Location in Settings.');
      expect(client.meshStatus.blockedReason, 'Turn on Location in Settings.');
      expect(client.meshStatus.eventModeRunning, isFalse);

      client.handleTaskData(const {'status': 'started', 'localEphemeralId': 5});
      expect(client.meshStatus.blockedReason, isNull);
      expect(client.meshStatus.eventModeRunning, isTrue);
    },
  );

  test(
    'mesh_metric with scan_fingerprint_mismatches sets and clears siteMismatchDetected',
    () async {
      client.handleTaskData(const {'status': 'started'});
      await Future<void>.delayed(Duration.zero);
      expect(client.meshStatus.siteMismatchDetected, isFalse);

      client.handleTaskData(const {
        'status': 'mesh_metric',
        'metrics': [
          {'kind': 'scan_fingerprint_mismatches', 'value': 2},
        ],
      });
      await Future<void>.delayed(Duration.zero);
      expect(client.meshStatus.siteMismatchDetected, isTrue);

      client.handleTaskData(const {
        'status': 'mesh_metric',
        'metrics': [
          {'kind': 'scan_fingerprint_mismatches', 'value': 0},
        ],
      });
      await Future<void>.delayed(Duration.zero);
      expect(client.meshStatus.siteMismatchDetected, isFalse);
    },
  );

  test(
    'correlates foreground acceptance, broadcast, and custody ACK to one SOS',
    () async {
      const eventId = 'sos-event-1';
      const objectId = 91;
      await database
          .into(database.outboxEvents)
          .insert(
            OutboxEventsCompanion.insert(
              eventId: eventId,
              objectId: const Value(objectId),
              siteId: 'site',
              roomId: 'public',
              payloadType: PayloadType.structuredSos.name,
              priority: PriorityBand.p0Critical.name,
              payload: Value(Uint8List.fromList([1])),
              createdAtMs: 1,
              updatedAtMs: 1,
              expiresAtMs: 9999999999999,
            ),
          );
      final events = <SosDeliveryEvent>[];
      client.onSosDelivery = events.add;

      client.handleTaskData(const {
        'status': 'mesh_submit_result',
        'objectId': objectId,
        'eventId': eventId,
        'accepted': true,
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      client.handleTaskData(const {
        'status': 'mesh_metric',
        'metrics': [
          {
            'kind': 'sos_alert_broadcast_started',
            'objectId': objectId,
            'detail': 'campaign verified',
          },
        ],
      });
      client.handleTaskData(const {
        'status': 'mesh_metric',
        'metrics': [
          {'kind': 'ack', 'objectId': objectId, 'peerId': 'receiver-1'},
        ],
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(events.map((event) => event.kind), [
        SosDeliveryEventKind.queued,
        SosDeliveryEventKind.broadcastStarted,
        SosDeliveryEventKind.relayConfirmed,
      ]);
      expect(events.every((event) => event.eventId == eventId), isTrue);
      expect(events.last.peerId, 'receiver-1');
    },
  );
}
