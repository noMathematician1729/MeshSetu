import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/outbox_sender.dart';
import 'package:meshsetu_mobile/core/model/model.dart';

Future<OutboxEvent> _insertReady(
  MeshDatabase database, {
  required String eventId,
  required String siteId,
  int objectId = 1,
}) async {
  await database
      .into(database.outboxEvents)
      .insert(
        OutboxEventsCompanion.insert(
          eventId: eventId,
          objectId: Value(objectId),
          siteId: siteId,
          roomId: 'public',
          payloadType: PayloadType.structuredSos.name,
          priority: PriorityBand.p0Critical.name,
          payload: Value(Uint8List.fromList([1, 2, 3])),
          state: const Value('ready'),
          createdAtMs: 1,
          updatedAtMs: 1,
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 60000,
        ),
      );
  return (await (database.select(
    database.outboxEvents,
  )..where((row) => row.eventId.equals(eventId))).getSingle());
}

Future<OutboxEvent> _waitForRow(
  MeshDatabase database,
  String eventId,
  bool Function(OutboxEvent row) predicate,
) async {
  for (var i = 0; i < 100; i++) {
    final row = await (database.select(
      database.outboxEvents,
    )..where((item) => item.eventId.equals(eventId))).getSingle();
    if (predicate(row)) return row;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  return (await (database.select(
    database.outboxEvents,
  )..where((item) => item.eventId.equals(eventId))).getSingle());
}

void main() {
  late MeshDatabase database;

  setUp(() => database = MeshDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'stops retrying and reports a terminal failure after the limit',
    () async {
      var attempts = 0;
      OutboxEvent? failedRow;
      Object? failure;
      final sender = OutboxSender(
        database,
        (_) async {
          attempts++;
          throw StateError('foreground mesh unavailable');
        },
        siteId: 'site-a',
        localEphemeralId: 7,
        maxAttempts: 3,
        retryBaseDelay: const Duration(milliseconds: 1),
        onDeliveryFailure: (row, error) {
          failedRow = row;
          failure = error;
        },
      );
      addTearDown(sender.dispose);
      await _insertReady(database, eventId: 'failed-sos', siteId: 'site-a');
      sender.start();

      final row = await _waitForRow(
        database,
        'failed-sos',
        (current) => current.state == 'failed',
      );

      expect(row.state, 'failed');
      expect(attempts, 3);
      expect(failedRow?.eventId, 'failed-sos');
      expect(failure.toString(), contains('foreground mesh unavailable'));
    },
  );

  test('transient submission failure recovers with bounded backoff', () async {
    var attempts = 0;
    final sender = OutboxSender(
      database,
      (_) async {
        attempts++;
        if (attempts < 2) throw StateError('try again');
      },
      siteId: 'site-a',
      localEphemeralId: 7,
      maxAttempts: 3,
      retryBaseDelay: const Duration(milliseconds: 1),
    );
    addTearDown(sender.dispose);
    await _insertReady(database, eventId: 'recovering-sos', siteId: 'site-a');
    sender.start();

    final row = await _waitForRow(
      database,
      'recovering-sos',
      (current) => current.state == 'relaying',
    );

    expect(row.state, 'relaying');
    expect(attempts, 2);
  });

  test(
    'late foreground acceptance reconciles a ready row without rehoming',
    () async {
      final sender = OutboxSender(
        database,
        (_) async {},
        siteId: 'site-a',
        localEphemeralId: 7,
      );
      addTearDown(sender.dispose);
      await _insertReady(
        database,
        eventId: 'late-sos',
        siteId: 'site-a',
        objectId: 42,
      );
      await _insertReady(
        database,
        eventId: 'foreign-sos',
        siteId: 'site-b',
        objectId: 43,
      );

      await sender.onSubmissionResult(42, accepted: true);

      final row = await (database.select(
        database.outboxEvents,
      )..where((item) => item.eventId.equals('late-sos'))).getSingle();
      final foreign = await (database.select(
        database.outboxEvents,
      )..where((item) => item.eventId.equals('foreign-sos'))).getSingle();
      expect(row.state, 'relaying');
      expect(foreign.state, 'ready');
    },
  );

  test(
    'claims a ready row before sending so concurrent senders cannot duplicate it',
    () async {
      var sends = 0;
      final sendGate = Completer<void>();
      Future<void> send(MeshEnvelope _) async {
        sends++;
        await sendGate.future;
      }

      final first = OutboxSender(
        database,
        send,
        siteId: 'site-a',
        localEphemeralId: 7,
      );
      final second = OutboxSender(
        database,
        send,
        siteId: 'site-a',
        localEphemeralId: 8,
      );
      addTearDown(() async {
        await first.dispose();
        await second.dispose();
      });
      await _insertReady(database, eventId: 'race-sos', siteId: 'site-a');
      first.start();
      second.start();

      await _waitForRow(database, 'race-sos', (row) => row.state == 'relaying');
      sendGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sends, 1);
    },
  );

  test('recovery only promotes relaying rows for the active site', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _insertReady(database, eventId: 'recover-site-a', siteId: 'site-a');
    await database.markState('recover-site-a', 'relaying', now);
    await _insertReady(database, eventId: 'recover-site-b', siteId: 'site-b');
    await database.markState('recover-site-b', 'relaying', now);

    var sends = 0;
    final sender = OutboxSender(
      database,
      (_) async {
        sends++;
      },
      siteId: 'site-a',
      localEphemeralId: 7,
      recoverRelaying: true,
    );
    addTearDown(sender.dispose);
    sender.start();
    final siteA = await _waitForRow(
      database,
      'recover-site-a',
      (row) => row.state == 'relaying',
    );
    final siteB = await (database.select(
      database.outboxEvents,
    )..where((row) => row.eventId.equals('recover-site-b'))).getSingle();

    expect(siteA.state, 'relaying');
    expect(siteB.state, 'relaying');
    expect(sends, 1);
  });
}
