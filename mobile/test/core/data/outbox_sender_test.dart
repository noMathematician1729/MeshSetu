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
    'a relaying row that expires mid-session with no ack is never reconciled today',
    () async {
      // Reproduces the field bug: no peer ever acknowledges custody (the
      // structured SOS GATT transfer never completes), so the row is stuck
      // on 'relaying' forever with no timeout, no expiry sweep, and no
      // visible failure. This is exactly what renders as an ungreen
      // "Relaying now" card that never changes. The row must enter
      // 'relaying' through the normal drain path (not be inserted directly
      // as 'relaying') so OutboxSender.start()'s one-time recovery sweep —
      // which only runs once, before this row even exists — cannot rescue
      // it and mask the bug.
      final sender = OutboxSender(
        database,
        (_) async {},
        siteId: 'site-a',
        localEphemeralId: 7,
        expirySweepInterval: const Duration(milliseconds: 20),
      );
      addTearDown(sender.dispose);
      sender.start();
      await _insertReady(
        database,
        eventId: 'stuck-sos',
        siteId: 'site-a',
        objectId: 99,
        // Expires almost immediately after entering 'relaying', so the
        // window genuinely elapses mid-session with no custody ack — the
        // exact condition that must not hang forever.
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 20,
      );
      final relaying = await _waitForRow(
        database,
        'stuck-sos',
        (current) => current.state == 'relaying',
      );
      expect(relaying.state, 'relaying');

      // Simulate the expiry window passing with no custody ack and no
      // second OutboxSender.start(). Neither an internal expiry sweep nor
      // an ack_timeout metric currently moves this row anywhere.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final row = await (database.select(
        database.outboxEvents,
      )..where((item) => item.eventId.equals('stuck-sos'))).getSingle();
      expect(
        row.state,
        isNot('relaying'),
        reason:
            'a relaying row with no ack must eventually reach a terminal '
            'state instead of hanging forever',
      );
    },
  );

  test(
    'an ack_timeout metric is surfaced into the outbox state machine',
    () async {
      var attempts = 0;
      final sender = OutboxSender(
        database,
        (_) async => attempts++,
        siteId: 'site-a',
        localEphemeralId: 7,
        maxAttempts: 5,
        retryBaseDelay: const Duration(milliseconds: 1),
      );
      addTearDown(sender.dispose);
      await _insertReady(
        database,
        eventId: 'timeout-sos',
        siteId: 'site-a',
        objectId: 55,
      );
      sender.start();
      await _waitForRow(
        database,
        'timeout-sos',
        (current) => current.state == 'relaying',
      );

      // The relay engine's own custody-ack timeout. Today OutboxSender.onMetrics
      // has no case for it, so the row never moves and the send callback is
      // never retried from this signal.
      await sender.onMetrics([const RelayMetric('ack_timeout', objectId: 55)]);

      final row = await _waitForRow(
        database,
        'timeout-sos',
        (current) => current.state != 'relaying',
      );
      expect(
        row.state,
        isNot('relaying'),
        reason: 'ack_timeout must move the row toward retry or failure',
      );
    },
  );

  test(
    'reports a diagnostic when an ack matches a row under a different site',
    () async {
      final diagnostics = <String>[];
      final sender = OutboxSender(
        database,
        (_) async {},
        siteId: 'site-a',
        localEphemeralId: 7,
        onDiagnostic: (kind, {detail}) => diagnostics.add(kind),
      );
      addTearDown(sender.dispose);
      // A row that exists only under a different active site.
      await _insertReady(
        database,
        eventId: 'foreign-site-sos',
        siteId: 'site-b',
        objectId: 77,
      );
      sender.start();

      await sender.onMetrics([const RelayMetric('ack', objectId: 77)]);

      expect(diagnostics, contains('ack_site_mismatch'));
      // The foreign row itself must be untouched: this instance must never
      // write across site boundaries even when reporting the mismatch.
      final foreign = await (database.select(
        database.outboxEvents,
      )..where((item) => item.eventId.equals('foreign-site-sos'))).getSingle();
      expect(foreign.state, 'ready');
    },
  );

  test(
    'does not report a diagnostic for a genuinely unknown objectId',
    () async {
      final diagnostics = <String>[];
      final sender = OutboxSender(
        database,
        (_) async {},
        siteId: 'site-a',
        localEphemeralId: 7,
        onDiagnostic: (kind, {detail}) => diagnostics.add(kind),
      );
      addTearDown(sender.dispose);
      sender.start();

      await sender.onMetrics([const RelayMetric('ack', objectId: 12345)]);

      expect(diagnostics, isEmpty);
    },
  );
}
