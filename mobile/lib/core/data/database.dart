import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Durable outbox/inbox for the Flutter app (Bible §2.5). Every locally
/// authored event (SOS draft, room message, voice manifest) has a state
/// machine `created -> ready -> relaying -> acked|expired`. This table is
/// the queue, not just UI storage: `feature/sos` and `feature/rooms` both
/// write rows here and `MeshTransportCoordinator` is fed from `ready` rows.
class OutboxEvents extends Table {
  TextColumn get eventId => text()(); // UUID, primary key
  IntColumn get objectId => integer().nullable()(); // assigned at finalize
  TextColumn get siteId => text()();
  TextColumn get roomId => text()();
  TextColumn get payloadType => text()(); // PayloadType enum name
  TextColumn get inputMode => text().nullable()(); // InputMode enum name
  TextColumn get rawText => text().nullable()();
  TextColumn get transcript => text().nullable()();
  TextColumn get triageJson => text().nullable()();
  TextColumn get voicePath => text().nullable()();
  TextColumn get priority => text()(); // PriorityBand enum name
  BlobColumn get payload => blob().nullable()(); // serialized app payload
  TextColumn get state => text().withDefault(const Constant('created'))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get expiresAtMs => integer()();

  @override
  Set<Column> get primaryKey => {eventId};
}

/// Reassembled objects received from peers (room chat + SOS forwarded to
/// this device), kept for UI display and dashboard/gateway evidence.
class InboxEvents extends Table {
  IntColumn get objectId => integer()();
  TextColumn get eventId => text()();
  TextColumn get siteId => text()();
  TextColumn get roomId => text()();
  TextColumn get payloadType => text()();
  BlobColumn get payload => blob()();
  TextColumn get peerId => text()();
  IntColumn get receivedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {objectId};
}

class SiteManifests extends Table {
  TextColumn get siteId => text()();
  TextColumn get siteName => text()();
  TextColumn get meshCode => text()();
  TextColumn get gatewayHint => text().nullable()();
  TextColumn get authorityKeyId => text().nullable()();
  TextColumn get authorityPublicKeyJwk => text().nullable()();
  IntColumn get validFromMs => integer()();
  IntColumn get validUntilMs => integer()();
  TextColumn get roomsJson => text()();
  IntColumn get joinedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {siteId};
}

/// Site manifest loaded via Mesh Code / QR join (Bible §3.1, `feature/join`).
/// Local, short-lived reverse-route footprints learned from authenticated SOS
/// traffic. The composite key permits at most one row per previous peer.
class ReverseRoutes extends Table {
  TextColumn get siteId => text()();
  TextColumn get eventId => text()();
  IntColumn get originEphemeralId => integer()();
  IntColumn get previousPeerEphemeralId => integer()();
  TextColumn get previousPeerHint => text().nullable()();
  IntColumn get learnedAtMs => integer()();
  IntColumn get learnedAtElapsedMs => integer().nullable()();
  IntColumn get expiresAtMs => integer()();
  IntColumn get observedForwardHopCount => integer()();
  IntColumn get lastReachableAtMs => integer().nullable()();
  IntColumn get consecutiveFailures =>
      integer().withDefault(const Constant(0))();
  RealColumn get qualityScore => real().nullable()();

  @override
  Set<Column> get primaryKey => {
    siteId,
    eventId,
    originEphemeralId,
    previousPeerEphemeralId,
  };
}

/// Durable gateway-downlink state. A row is not DELIVERED until a verified
/// sender-side RESPONSE_DELIVERED receipt reaches the server.
class AuthorityResponseOutbox extends Table {
  TextColumn get responseId => text()();
  TextColumn get replyToEventId => text()();
  IntColumn get destinationEphemeralId => integer()();
  BlobColumn get signedPayload => blob()();
  IntColumn get meshObjectId => integer().nullable()();
  IntColumn get hopCount => integer().withDefault(const Constant(0))();
  TextColumn get state => text()();
  TextColumn get routeMode => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get attemptedPeerIdsJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get nextAttemptAtMs => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  BlobColumn get traceId => blob().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer()();

  @override
  Set<Column> get primaryKey => {responseId};
}

/// Only cryptographically verified responses are persisted here. This table
/// is also the durable display dedupe boundary after process restart.
class AuthorityInbox extends Table {
  TextColumn get responseId => text()();
  TextColumn get replyToEventId => text()();
  TextColumn get siteId => text()();
  TextColumn get responseType => text()();
  TextColumn get messageText => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer()();
  IntColumn get receivedAtMs => integer()();
  BlobColumn get originalTraceId => blob().nullable()();

  @override
  Set<Column> get primaryKey => {responseId};
}

class ResponseReceipts extends Table {
  TextColumn get receiptId => text()();
  TextColumn get responseId => text()();
  TextColumn get replyToEventId => text()();
  IntColumn get senderEphemeralId => integer()();
  IntColumn get createdAtMs => integer()();
  TextColumn get state => text().withDefault(const Constant('READY'))();

  @override
  Set<Column> get primaryKey => {receiptId};
}

@DriftDatabase(
  tables: [
    OutboxEvents,
    InboxEvents,
    SiteManifests,
    ReverseRoutes,
    AuthorityResponseOutbox,
    AuthorityInbox,
    ResponseReceipts,
  ],
)
class MeshDatabase extends _$MeshDatabase {
  MeshDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  MeshDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createReturnChannelIndexes(m);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(reverseRoutes);
        await m.createTable(authorityResponseOutbox);
        await m.createTable(authorityInbox);
        await m.createTable(responseReceipts);
        await _createReturnChannelIndexes(m);
      }
    },
  );

  Future<void> _createReturnChannelIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reverse_route_key '
      'ON reverse_routes(site_id, event_id, origin_ephemeral_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_reverse_route_expiry '
      'ON reverse_routes(expires_at_ms)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_response_outbox_state '
      'ON authority_response_outbox(state, expires_at_ms)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_authority_inbox_expiry '
      'ON authority_inbox(expires_at_ms)',
    );
  }

  static QueryExecutor _open() =>
      driftDatabase(name: 'meshsetu', native: const DriftNativeOptions());

  Stream<List<OutboxEvent>> watchReady(String siteId) => (select(
    outboxEvents,
  )..where((t) => t.siteId.equals(siteId) & t.state.equals('ready'))).watch();

  /// Watches a single outbox row by [eventId] — e.g. the emergency active
  /// screen's delivery status for the SOS it just queued. Emits null once
  /// the row no longer exists (should not normally happen; rows are never
  /// deleted, only state-transitioned).
  Stream<OutboxEvent?> watchEvent(String eventId) => (select(
    outboxEvents,
  )..where((t) => t.eventId.equals(eventId))).watchSingleOrNull();

  Stream<List<OutboxEvent>> watchRoom(String siteId, String roomId) =>
      (select(outboxEvents)
            ..where((t) => t.siteId.equals(siteId) & t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
          .watch();

  Stream<List<InboxEvent>> watchInboxRoom(String siteId, String roomId) =>
      (select(inboxEvents)
            ..where((t) => t.siteId.equals(siteId) & t.roomId.equals(roomId))
            ..orderBy([(t) => OrderingTerm.asc(t.receivedAtMs)]))
          .watch();

  Stream<List<InboxEvent>> watchInboxSite(String siteId) =>
      (select(inboxEvents)
            ..where((t) => t.siteId.equals(siteId))
            ..orderBy([(t) => OrderingTerm.asc(t.receivedAtMs)]))
          .watch();

  Future<void> markState(String eventId, String state, int nowMs) =>
      (update(outboxEvents)..where((t) => t.eventId.equals(eventId))).write(
        OutboxEventsCompanion(state: Value(state), updatedAtMs: Value(nowMs)),
      );

  Future<void> expireOverdue(int nowMs) =>
      (update(outboxEvents)..where(
            (t) =>
                t.expiresAtMs.isSmallerThanValue(nowMs) &
                t.state.isNotValue('acked'),
          ))
          .write(
            OutboxEventsCompanion(
              state: const Value('expired'),
              updatedAtMs: Value(nowMs),
            ),
          );

  Future<void> insertInbox(InboxEventsCompanion row) =>
      into(inboxEvents).insertOnConflictUpdate(row);

  /// Locally authored SOS rows that have been finalized (payload and object
  /// ID assigned) and are therefore eligible for upload to the control room.
  /// Delivery to the admin backend is independent of mesh custody: a row with
  /// no peer to relay through still needs to reach the dashboard as soon as
  /// this device has internet.
  Future<List<OutboxEvent>> finalizedSosEvents() =>
      (select(outboxEvents)..where(
            (t) =>
                t.payloadType.equals('structuredSos') &
                t.state.isNotValue('created'),
          ))
          .get();

  Future<SiteManifest?> currentSite() async {
    final rows = await (select(
      siteManifests,
    )..orderBy([(t) => OrderingTerm.desc(t.joinedAtMs)])).get();
    return rows.isEmpty ? null : rows.first;
  }
}
