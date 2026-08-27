import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/return_channel_dao.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:test/test.dart';

void main() {
  late MeshDatabase db;
  late int now;

  setUp(() {
    db = MeshDatabase.forTesting(NativeDatabase.memory());
    now = 1000;
  });
  tearDown(() => db.close());

  MeshEnvelope sos({int expiresAtMs = 5000, int hopCount = 1}) => MeshEnvelope(
    objectId: 10,
    eventId: 'event-1',
    siteId: 'site-1',
    roomId: 'public',
    createdAtMs: 1,
    expiresAtMs: expiresAtMs,
    hopCount: hopCount,
    hopLimit: 6,
    priority: PriorityBand.p0Critical,
    payloadType: PayloadType.structuredSos,
    payload: Uint8List.fromList([1]),
    originEphemeralId: 99,
  );

  test(
    'learns two freshest route candidates and never exceeds the cap',
    () async {
      final routes = ReverseRouteRepository(
        db,
        clockMs: () => now,
        config: const ReturnChannelConfig(routeCacheTtlMs: 10000),
      );
      await routes.observeValidSos(
        envelope: sos(),
        previousPeerEphemeralId: 101,
      );
      now = 1001;
      await routes.observeValidSos(
        envelope: sos(),
        previousPeerEphemeralId: 202,
      );
      now = 1002;
      await routes.observeValidSos(
        envelope: sos(),
        previousPeerEphemeralId: 303,
      );

      final candidates = await routes.candidates(
        siteId: 'site-1',
        eventId: 'event-1',
        originEphemeralId: 99,
        nowMs: now,
      );
      expect(candidates, hasLength(2));
      expect(candidates.map((row) => row.previousPeerEphemeralId), [303, 202]);

      now = 1003;
      await routes.observeValidSos(
        envelope: sos(),
        previousPeerEphemeralId: 202,
      );
      expect(
        (await routes.candidates(
          siteId: 'site-1',
          eventId: 'event-1',
          originEphemeralId: 99,
        )).map((row) => row.previousPeerEphemeralId),
        [202, 303],
      );
    },
  );

  test(
    'route expiry is bounded by original SOS expiry and exact boundary cleanup',
    () async {
      final routes = ReverseRouteRepository(db, clockMs: () => now);
      await routes.observeValidSos(
        envelope: sos(expiresAtMs: 1100),
        previousPeerEphemeralId: 7,
      );
      now = 1100;
      expect(
        await routes.candidates(
          siteId: 'site-1',
          eventId: 'event-1',
          originEphemeralId: 99,
        ),
        isEmpty,
      );
      expect(await routes.deleteExpired(), 1);
    },
  );

  test(
    'response outbox and verified inbox remain durable and deduplicated',
    () async {
      final responses = AuthorityResponseRepository(db, clockMs: () => now);
      await responses.enqueue(
        responseId: 'response-1',
        replyToEventId: 'event-1',
        destinationEphemeralId: 99,
        signedPayload: Uint8List.fromList([1, 2, 3]),
        meshObjectId: 77,
        createdAtMs: now,
        expiresAtMs: 5000,
      );
      expect((await responses.get('response-1'))!.state, 'READY');
      await responses.markRetry(
        'response-1',
        nextAttemptAtMs: 2000,
        error: 'peer unavailable',
      );
      expect((await responses.get('response-1'))!.state, 'RETRY');
      await responses.markDelivered('response-1');
      expect((await responses.get('response-1'))!.state, 'DELIVERED');

      final row = AuthorityInboxCompanion.insert(
        responseId: 'response-1',
        replyToEventId: 'event-1',
        siteId: 'site-1',
        responseType: 'sosReceived',
        messageText: 'received',
        createdAtMs: 1,
        expiresAtMs: 5000,
        receivedAtMs: now,
      );
      expect(await responses.persistVerified(row), isTrue);
      expect(await responses.persistVerified(row), isFalse);
      expect(await responses.hasVerified('response-1'), isTrue);
    },
  );
  test('upgrades a v1 file without deleting existing outbox data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'meshsetu-migration-',
    );
    final file = File('${directory.path}/legacy.sqlite');
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('''CREATE TABLE outbox_events (
      event_id TEXT NOT NULL PRIMARY KEY,
      object_id INTEGER,
      site_id TEXT NOT NULL,
      room_id TEXT NOT NULL,
      payload_type TEXT NOT NULL,
      input_mode TEXT,
      raw_text TEXT,
      transcript TEXT,
      triage_json TEXT,
      voice_path TEXT,
      priority TEXT NOT NULL,
      payload BLOB,
      state TEXT NOT NULL DEFAULT 'created',
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      expires_at_ms INTEGER NOT NULL
    )''');
    raw.execute('PRAGMA user_version = 1');
    raw.execute(
      "INSERT INTO outbox_events (event_id, site_id, room_id, payload_type, priority, created_at_ms, updated_at_ms, expires_at_ms) VALUES ('legacy-event', 'site-1', 'public', 'structuredSos', 'p0Critical', 1, 1, 9999)",
    );
    raw.close();

    final migrated = MeshDatabase(NativeDatabase(file));
    addTearDown(() async {
      await migrated.close();
      await directory.delete(recursive: true);
    });
    final row = await (migrated.select(
      migrated.outboxEvents,
    )..where((table) => table.eventId.equals('legacy-event'))).getSingle();
    expect(row.siteId, 'site-1');
    expect(row.state, 'created');
    expect(await (migrated.select(migrated.reverseRoutes)).get(), isEmpty);
    expect(
      await (migrated.select(migrated.authorityResponseOutbox)).get(),
      isEmpty,
    );
  });
}
