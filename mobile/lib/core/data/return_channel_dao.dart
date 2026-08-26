import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../model/model.dart';
import 'database.dart';

final class ReturnChannelConfig {
  const ReturnChannelConfig({
    this.routeCacheTtlMs = 10 * 60 * 1000,
    this.responseTtlMs = 5 * 60 * 1000,
    this.maxRouteCandidates = 2,
    this.maxFallbackPeers = 2,
    this.returnHopLimit = 6,
    this.maxResponseCache = 4096,
    this.backoffMs = const [500, 1000, 2000, 4000],
  });

  final int routeCacheTtlMs;
  final int responseTtlMs;
  final int maxRouteCandidates;
  final int maxFallbackPeers;
  final int returnHopLimit;
  final int maxResponseCache;
  final List<int> backoffMs;
}

final class ReverseRouteRepository {
  ReverseRouteRepository(
    this.db, {
    this.config = const ReturnChannelConfig(),
    this.clockMs = _systemClock,
  });

  final MeshDatabase db;
  final ReturnChannelConfig config;
  final int Function() clockMs;

  Future<void> observeValidSos({
    required MeshEnvelope envelope,
    required int previousPeerEphemeralId,
    String? previousPeerHint,
    int? learnedAtElapsedMs,
  }) async {
    final now = clockMs();
    final expiry = math.min(envelope.expiresAtMs, now + config.routeCacheTtlMs);
    if (expiry <= now) return;
    await db.transaction(() async {
      final existing =
          await (db.select(db.reverseRoutes)..where(
                (t) =>
                    t.siteId.equals(envelope.siteId) &
                    t.eventId.equals(envelope.eventId) &
                    t.originEphemeralId.equals(envelope.originEphemeralId) &
                    t.previousPeerEphemeralId.equals(previousPeerEphemeralId),
              ))
              .getSingleOrNull();
      await db
          .into(db.reverseRoutes)
          .insertOnConflictUpdate(
            ReverseRoutesCompanion.insert(
              siteId: envelope.siteId,
              eventId: envelope.eventId,
              originEphemeralId: envelope.originEphemeralId,
              previousPeerEphemeralId: previousPeerEphemeralId,
              previousPeerHint: Value(previousPeerHint),
              learnedAtMs: now,
              learnedAtElapsedMs: Value(learnedAtElapsedMs),
              expiresAtMs: expiry,
              observedForwardHopCount: envelope.hopCount,
              lastReachableAtMs: Value(existing?.lastReachableAtMs),
              consecutiveFailures: Value(existing?.consecutiveFailures ?? 0),
              qualityScore: Value(existing?.qualityScore),
            ),
          );
      final rows = await _candidates(
        siteId: envelope.siteId,
        eventId: envelope.eventId,
        originEphemeralId: envelope.originEphemeralId,
        nowMs: now,
      );
      for (final row in rows.skip(config.maxRouteCandidates)) {
        await (db.delete(db.reverseRoutes)..where(
              (t) =>
                  t.siteId.equals(row.siteId) &
                  t.eventId.equals(row.eventId) &
                  t.originEphemeralId.equals(row.originEphemeralId) &
                  t.previousPeerEphemeralId.equals(row.previousPeerEphemeralId),
            ))
            .go();
      }
    });
  }

  Future<List<ReverseRoute>> candidates({
    required String siteId,
    required String eventId,
    required int originEphemeralId,
    int? nowMs,
  }) => _candidates(
    siteId: siteId,
    eventId: eventId,
    originEphemeralId: originEphemeralId,
    nowMs: nowMs ?? clockMs(),
  );

  Future<void> markReachable(ReverseRoute route, {int? nowMs}) async {
    await (db.update(db.reverseRoutes)..where(
          (t) =>
              t.siteId.equals(route.siteId) &
              t.eventId.equals(route.eventId) &
              t.originEphemeralId.equals(route.originEphemeralId) &
              t.previousPeerEphemeralId.equals(route.previousPeerEphemeralId),
        ))
        .write(
          ReverseRoutesCompanion(
            lastReachableAtMs: Value(nowMs ?? clockMs()),
            consecutiveFailures: const Value(0),
          ),
        );
  }

  Future<void> markFailure(ReverseRoute route) async {
    await (db.update(db.reverseRoutes)..where(
          (t) =>
              t.siteId.equals(route.siteId) &
              t.eventId.equals(route.eventId) &
              t.originEphemeralId.equals(route.originEphemeralId) &
              t.previousPeerEphemeralId.equals(route.previousPeerEphemeralId),
        ))
        .write(
          ReverseRoutesCompanion(
            consecutiveFailures: Value(route.consecutiveFailures + 1),
          ),
        );
  }

  Future<int> deleteExpired({int? nowMs}) =>
      (db.delete(db.reverseRoutes)..where(
            (t) => t.expiresAtMs.isSmallerOrEqualValue(nowMs ?? clockMs()),
          ))
          .go();

  Future<List<ReverseRoute>> _candidates({
    required String siteId,
    required String eventId,
    required int originEphemeralId,
    required int nowMs,
  }) =>
      (db.select(db.reverseRoutes)
            ..where(
              (t) =>
                  t.siteId.equals(siteId) &
                  t.eventId.equals(eventId) &
                  t.originEphemeralId.equals(originEphemeralId) &
                  t.expiresAtMs.isBiggerThanValue(nowMs),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.consecutiveFailures),
              (t) => OrderingTerm.desc(t.lastReachableAtMs),
              (t) => OrderingTerm.desc(t.learnedAtMs),
              (t) => OrderingTerm.asc(t.observedForwardHopCount),
              (t) => OrderingTerm.asc(t.previousPeerEphemeralId),
            ])
            ..limit(config.maxRouteCandidates))
          .get();

  static int _systemClock() => DateTime.now().millisecondsSinceEpoch;
}

final class AuthorityResponseRepository {
  AuthorityResponseRepository(this.db, {this.clockMs = _systemClock});

  final MeshDatabase db;
  final int Function() clockMs;

  Future<void> enqueue({
    required String responseId,
    required String replyToEventId,
    required int destinationEphemeralId,
    required Uint8List signedPayload,
    required int meshObjectId,
    int hopCount = 0,
    required int createdAtMs,
    required int expiresAtMs,
    Uint8List? traceId,
  }) => db
      .into(db.authorityResponseOutbox)
      .insertOnConflictUpdate(
        AuthorityResponseOutboxCompanion.insert(
          responseId: responseId,
          replyToEventId: replyToEventId,
          destinationEphemeralId: destinationEphemeralId,
          signedPayload: signedPayload,
          meshObjectId: Value(meshObjectId),
          hopCount: Value(hopCount),
          state: 'READY',
          traceId: Value(traceId),
          createdAtMs: createdAtMs,
          expiresAtMs: expiresAtMs,
        ),
      );

  Future<AuthorityResponseOutboxData?> get(String responseId) => (db.select(
    db.authorityResponseOutbox,
  )..where((t) => t.responseId.equals(responseId))).getSingleOrNull();

  Future<List<AuthorityResponseOutboxData>> ready({int? nowMs}) =>
      (db.select(db.authorityResponseOutbox)
            ..where(
              (t) =>
                  (t.state.equals('READY') | t.state.equals('RETRY')) &
                  t.expiresAtMs.isBiggerThanValue(nowMs ?? clockMs()) &
                  (t.nextAttemptAtMs.isNull() |
                      t.nextAttemptAtMs.isSmallerOrEqualValue(
                        nowMs ?? clockMs(),
                      )),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
          .get();

  Future<void> markForwarding(String responseId, String routeMode) => _write(
    responseId,
    AuthorityResponseOutboxCompanion(
      state: const Value('FORWARDING'),
      routeMode: Value(routeMode),
      attempts: const Value.absent(),
    ),
  );

  Future<void> markRetry(
    String responseId, {
    required int nextAttemptAtMs,
    String? error,
  }) => _write(
    responseId,
    AuthorityResponseOutboxCompanion(
      state: const Value('RETRY'),
      nextAttemptAtMs: Value(nextAttemptAtMs),
      lastError: Value(error),
    ),
  );

  Future<void> markDelivered(String responseId) => _write(
    responseId,
    const AuthorityResponseOutboxCompanion(state: Value('DELIVERED')),
  );

  Future<void> markExpired(String responseId) => _write(
    responseId,
    const AuthorityResponseOutboxCompanion(state: Value('EXPIRED')),
  );

  Future<void> markFailed(String responseId, String error) => _write(
    responseId,
    AuthorityResponseOutboxCompanion(
      state: const Value('FAILED'),
      lastError: Value(error),
    ),
  );

  Future<void> incrementAttempt(String responseId) => db.customUpdate(
    'UPDATE authority_response_outbox SET attempts = attempts + 1 '
    'WHERE response_id = ?1',
    variables: [Variable<String>(responseId)],
    updates: {db.authorityResponseOutbox},
  );

  Future<bool> persistVerified(AuthorityInboxCompanion row) async {
    final responseId = row.responseId.value;
    if (await hasVerified(responseId)) return false;
    await db
        .into(db.authorityInbox)
        .insert(row, mode: InsertMode.insertOrIgnore);
    return true;
  }

  Future<bool> hasVerified(String responseId) async =>
      (await (db.select(
        db.authorityInbox,
      )..where((t) => t.responseId.equals(responseId))).getSingleOrNull()) !=
      null;

  Future<void> enqueueReceipt(ResponseReceiptsCompanion row) =>
      db.into(db.responseReceipts).insert(row, mode: InsertMode.insertOrIgnore);

  Future<List<ResponseReceipt>> readyReceipts() =>
      (db.select(db.responseReceipts)
            ..where((table) => table.state.equals('READY'))
            ..orderBy([(table) => OrderingTerm.asc(table.createdAtMs)]))
          .get();

  Future<void> markReceiptUploaded(String receiptId) =>
      (db.update(db.responseReceipts)
            ..where((table) => table.receiptId.equals(receiptId)))
          .write(const ResponseReceiptsCompanion(state: Value('UPLOADED')));

  Future<int> cleanupExpired({int? nowMs}) async {
    final now = nowMs ?? clockMs();
    final routes = await (db.delete(
      db.reverseRoutes,
    )..where((t) => t.expiresAtMs.isSmallerOrEqualValue(now))).go();
    final responses =
        await (db.update(db.authorityResponseOutbox)..where(
              (t) =>
                  t.expiresAtMs.isSmallerOrEqualValue(now) &
                  t.state.isNotIn(['DELIVERED', 'EXPIRED']),
            ))
            .write(
              const AuthorityResponseOutboxCompanion(state: Value('EXPIRED')),
            );
    return routes + responses;
  }

  Future<void> _write(
    String responseId,
    AuthorityResponseOutboxCompanion values,
  ) => (db.update(
    db.authorityResponseOutbox,
  )..where((t) => t.responseId.equals(responseId))).write(values);

  static int _systemClock() => DateTime.now().millisecondsSinceEpoch;
}
