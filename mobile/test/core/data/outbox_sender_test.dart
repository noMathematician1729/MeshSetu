import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/outbox_sender.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/core/protocol/relay_engine.dart';

Future<OutboxEvent> _insertReady(
  MeshDatabase database, {
  required String eventId,
  required String siteId,
  int objectId = 1,
  int? expiresAtMs,
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
          expiresAtMs:
              expiresAtMs ?? DateTime.now().millisecondsSinceEpoch + 60000,
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
    'expires a relaying SOS when no custody acknowledgement arrives',
    () async {
      final sender = OutboxSender(
        database,
        (_) async {},
        siteId: 'site-a',
        localEphemeralId: 7,
        expirySweepInterval: const Duration(milliseconds: 5),
      );
      addTearDown(sender.dispose);
      sender.start();
      await _insertReady(
        database,
        eventId: 'expired-sos',
        siteId: 'site-a',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 20,
      );

      final row = await _waitForRow(
        database,
        'expired-sos',
        (current) => current.state == 'expired',
      );
      expect(row.state, 'expired');
    },
  );

  test('fails after bounded custody acknowledgement timeouts', () async {
    final sender = OutboxSender(
      database,
      (_) async {},
      siteId: 'site-a',
      localEphemeralId: 7,
    );
    addTearDown(sender.dispose);
    await _insertReady(
      database,
      eventId: 'timed-out-sos',
      siteId: 'site-a',
      objectId: 55,
    );
    sender.start();
    await _waitForRow(
      database,
      'timed-out-sos',
      (current) => current.state == 'relaying',
    );

    for (var i = 0; i < OutboxSender.maxAckTimeoutAttempts; i++) {
      await sender.onMetrics(const [RelayMetric('ack_timeout', objectId: 55)]);
      if (i + 1 < OutboxSender.maxAckTimeoutAttempts) {
        await _waitForRow(
          database,
          'timed-out-sos',
          (current) => current.state == 'relaying',
        );
      }
    }

    final row = await _waitForRow(
      database,
      'timed-out-sos',
      (current) => current.state == 'failed',
    );
    expect(row.state, 'failed');
  });
}
