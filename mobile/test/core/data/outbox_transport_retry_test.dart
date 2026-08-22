import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/outbox_sender.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:test/test.dart';

Future<void> _insertReadyRoomMessage(
  MeshDatabase db, {
  String eventId = 'msg-1',
  int objectId = 501,
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
          payloadType: PayloadType.roomMessage.name,
          priority: PriorityBand.p2Normal.name,
          payload: Value(Uint8List.fromList([1, 2, 3])),
          state: const Value('ready'),
          createdAtMs: now,
          updatedAtMs: now,
          expiresAtMs: now + 3600000,
        ),
      );
}

Future<String?> _stateOf(MeshDatabase db, String eventId) async {
  final row = await (db.select(
    db.outboxEvents,
  )..where((t) => t.eventId.equals(eventId))).getSingleOrNull();
  return row?.state;
}

void main() {
  late MeshDatabase db;

  setUp(() => db = MeshDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'a radio that is not up yet never permanently fails a message',
    () async {
      var attempts = 0;
      final sender = OutboxSender(
        db,
        (_) async {
          attempts++;
          throw const MeshTransportUnavailable('event mode is not running');
        },
        siteId: 'demo-site',
        localEphemeralId: 7,
        maxAttempts: 2,
        retryBaseDelay: const Duration(milliseconds: 5),
        transportRetryDelay: const Duration(milliseconds: 5),
      );
      addTearDown(sender.dispose);

      await _insertReadyRoomMessage(db);
      sender.start();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Many attempts, but the message stays queued for a later drain instead
      // of being marked failed and lost.
      expect(attempts, greaterThan(2));
      expect(await _stateOf(db, 'msg-1'), 'ready');
    },
  );

  test('a genuine rejection still fails the row after maxAttempts', () async {
    var attempts = 0;
    final sender = OutboxSender(
      db,
      (_) async {
        attempts++;
        throw StateError('foreground mesh rejected object');
      },
      siteId: 'demo-site',
      localEphemeralId: 7,
      maxAttempts: 2,
      retryBaseDelay: const Duration(milliseconds: 5),
    );
    addTearDown(sender.dispose);

    await _insertReadyRoomMessage(db, eventId: 'msg-2', objectId: 502);
    sender.start();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(attempts, 2);
    expect(await _stateOf(db, 'msg-2'), 'failed');
  });
}
