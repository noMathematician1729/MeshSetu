import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meshsetu_mobile/core/ble/gatt_peer_session.dart';
import 'package:meshsetu_mobile/core/ble/gatt_server.dart';
import 'package:meshsetu_mobile/core/ble/mesh_transport.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/data/outbox_sender.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/core/protocol/relay_engine.dart';
import 'package:meshsetu_mobile/core/protocol/secure_envelope.dart';
import 'package:meshsetu_mobile/feature/rooms/room_message_dispatcher.dart';
import 'package:meshsetu_mobile/feature/rooms/room_policy.dart';
import 'package:meshsetu_mobile/feature/rooms/room_presence_socket.dart';
import 'package:meshsetu_mobile/feature/rooms/room_repository.dart';
import 'package:meshsetu_mobile/feature/rooms/room_voice_packet.dart';
import 'package:test/test.dart';
import 'package:universal_ble/universal_ble.dart';

/// Implements both live interfaces, exactly as [RoomPresenceSocket] does, so
/// the dispatcher's runtime `is LiveRoomVoiceTransport` check sees a voice-
/// capable transport.
class _FakeLiveTransport implements LiveRoomVoiceTransport {
  _FakeLiveTransport({required this.canReachOtherMember, required this.result});

  @override
  final bool canReachOtherMember;
  final bool result;
  final voiceSent = <({String messageId, int bytes, int durationMs})>[];
  final textSent = <String>[];

  @override
  Future<bool> sendRoomMessage({
    required String messageId,
    required String text,
  }) async {
    textSent.add(text);
    return result;
  }

  @override
  Future<bool> sendRoomVoice({
    required String messageId,
    required Uint8List audio,
    required int durationMs,
  }) async {
    voiceSent.add((
      messageId: messageId,
      bytes: audio.length,
      durationMs: durationMs,
    ));
    return result;
  }
}

/// Text-only transport: proves the dispatcher falls back to the mesh rather
/// than crashing when the live channel cannot carry audio.
class _TextOnlyTransport implements LiveRoomMessageTransport {
  @override
  bool get canReachOtherMember => true;

  @override
  Future<bool> sendRoomMessage({
    required String messageId,
    required String text,
  }) async => true;
}

class _MemoryRelayStore extends RelayStore {
  @override
  void persist(MeshEnvelope envelope, {Uint8List? encryptedBytes}) {}
}

class _NoopPeripheral extends UniversalBlePeripheralUnsupported {
  @override
  Future<void> clearServices() async {}
}

class _PairedMeshLink implements PeerLink {
  final _incoming = StreamController<Uint8List>.broadcast();
  final _state = StreamController<PeerSessionState>.broadcast();
  late final _PairedMeshLink peer;

  @override
  int get mtu => 185;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Stream<PeerSessionState> get state => _state.stream;

  @override
  Future<bool> send(Uint8List bytes, {bool withResponse = true}) async {
    peer._incoming.add(bytes);
    return true;
  }

  @override
  Future<void> close() async {
    await _incoming.close();
    await _state.close();
  }
}

MeshTransportCoordinator _meshCoordinator() => MeshTransportCoordinator(
  server: MeshGattServer(),
  relay: MeshRelayEngine(
    siteId: 'site',
    crypto: AeadEnvelope(List<int>.filled(32, 7)),
    store: _MemoryRelayStore(),
    clockMs: () => DateTime.now().millisecondsSinceEpoch,
  ),
);

Uint8List _clip([int length = 1200]) =>
    Uint8List.fromList(List<int>.generate(length, (i) => (i * 7 + 3) % 256));

final _publicPolicy = policyForRole('public', 'public');
const _publicRoles = {'public'};

void main() {
  late MeshDatabase db;
  late RoomRepository repository;

  setUp(() {
    db = MeshDatabase.forTesting(NativeDatabase.memory());
    repository = RoomRepository(db, siteId: 'site');
  });

  tearDown(() => db.close());

  group('RoomRepository.sendVoiceMessage', () {
    test('queues a roomVoice row carrying an authenticated packet', () async {
      final audio = _clip();

      final eventId = await repository.sendVoiceMessage(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: audio,
        durationMs: 2400,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(eventId))).getSingle();
      expect(row.payloadType, PayloadType.roomVoice.name);
      expect(row.priority, PriorityBand.p3Bulk.name);
      expect(row.inputMode, InputMode.voice.name);
      expect(row.rawText, null);
      expect(row.state, RoomRepository.meshReadyState);

      final content = RoomVoicePacketCodec.decode(
        siteId: 'site',
        roomId: 'public',
        eventId: eventId,
        packet: Uint8List.fromList(row.payload!),
      );
      expect(content.audio, audio);
      expect(content.durationMs, 2400);
    });

    test('encodes the resolved display name into the packet', () async {
      final named = RoomRepository(
        db,
        siteId: 'site',
        localDisplayName: () async => '  Priya  ',
      );

      final eventId = await named.sendVoiceMessage(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(),
        durationMs: 1000,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(eventId))).getSingle();
      expect(
        RoomVoicePacketCodec.decode(
          siteId: 'site',
          roomId: 'public',
          eventId: eventId,
          packet: Uint8List.fromList(row.payload!),
        ).senderName,
        'Priya',
      );
    });

    test('refuses a room the caller may not post in', () {
      expect(
        () => repository.sendVoiceMessage(
          policy: policyForRole('medical', 'medical'),
          userRoles: _publicRoles,
          audio: _clip(),
          durationMs: 1000,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('refuses empty audio, oversized audio, and bad durations', () {
      expect(
        () => repository.sendVoiceMessage(
          policy: _publicPolicy,
          userRoles: _publicRoles,
          audio: Uint8List(0),
          durationMs: 1000,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => repository.sendVoiceMessage(
          policy: _publicPolicy,
          userRoles: _publicRoles,
          audio: _clip(RoomVoicePacketCodec.maxAudioBytes + 1),
          durationMs: 1000,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => repository.sendVoiceMessage(
          policy: _publicPolicy,
          userRoles: _publicRoles,
          audio: _clip(),
          durationMs: RoomVoicePacketCodec.maxDurationMs + 1,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('RoomRepository.watch', () {
    test('surfaces a sent voice note as a voice message, not empty text', () async {
      final eventId = await repository.sendVoiceMessage(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(900),
        durationMs: 3000,
      );

      final messages = await repository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .firstWhere((items) => items.isNotEmpty);

      final message = messages.single;
      expect(message.eventId, eventId);
      expect(message.mine, isTrue);
      expect(message.isVoice, isTrue);
      expect(message.text, isEmpty);
      expect(message.voice!.durationMs, 3000);
      expect(message.voice!.audio, hasLength(900));
      expect(message.voice!.duration, const Duration(seconds: 3));
      expect(message.state, RoomMessageState.queued);
    });

    test('mixes voice and text in timestamp order', () async {
      await repository.storeSocketMessage(
        roomId: 'public',
        eventId: 'text-early',
        text: 'first',
        fromPeerId: 'Remote',
        sentAtMs: 1000,
      );
      await repository.storeSocketVoiceMessage(
        roomId: 'public',
        eventId: 'voice-later',
        audio: _clip(300),
        durationMs: 1500,
        fromPeerId: 'Remote',
        sentAtMs: 2000,
      );

      final messages = await repository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .firstWhere((items) => items.length == 2);

      expect(messages.map((m) => m.eventId), ['text-early', 'voice-later']);
      expect(messages.first.isVoice, isFalse);
      expect(messages.last.isVoice, isTrue);
      expect(messages.last.fromPeerId, 'Remote');
    });

    test('drops a tampered voice payload instead of rendering it', () async {
      await repository.storeSocketVoiceMessage(
        roomId: 'public',
        eventId: 'tampered',
        audio: _clip(200),
        durationMs: 1200,
        fromPeerId: 'Remote',
        sentAtMs: 5,
      );
      final row = await db.select(db.inboxEvents).getSingle();
      final corrupted = Uint8List.fromList(row.payload);
      corrupted[RoomVoicePacketCodec.headerBytes + 4] ^= 0xFF;
      await db.insertInbox(
        InboxEventsCompanion.insert(
          objectId: Value(row.objectId),
          eventId: row.eventId,
          siteId: row.siteId,
          roomId: row.roomId,
          payloadType: row.payloadType,
          payload: corrupted,
          peerId: row.peerId,
          receivedAtMs: row.receivedAtMs,
        ),
      );

      final messages = await repository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .first;

      expect(messages, isEmpty);
    });

    test('duplicate socket voice deliveries converge on one row', () async {
      for (var i = 0; i < 2; i++) {
        await repository.storeSocketVoiceMessage(
          roomId: 'public',
          eventId: 'repeat',
          audio: _clip(150),
          durationMs: 800,
          fromPeerId: 'Remote',
          sentAtMs: 9,
        );
      }

      expect(await db.select(db.inboxEvents).get(), hasLength(1));
    });

    test('a voice note relayed back to its author is not shown twice', () async {
      final eventId = await repository.sendVoiceMessage(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(400),
        durationMs: 1500,
      );
      final sent = await (db.select(
        db.outboxEvents,
      )..where((t) => t.eventId.equals(eventId))).getSingle();
      await db.insertInbox(
        InboxEventsCompanion.insert(
          objectId: Value(sent.objectId!),
          eventId: eventId,
          siteId: 'site',
          roomId: 'public',
          payloadType: sent.payloadType,
          payload: Uint8List.fromList(sent.payload!),
          peerId: 'peer-b',
          receivedAtMs: 50,
        ),
      );

      final messages = await repository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .first;

      expect(messages, hasLength(1));
      expect(messages.single.mine, isTrue);
      expect(messages.single.isVoice, isTrue);
    });

    test('a text message relayed back to its author is not shown twice', () async {
      final eventId = await repository.sendMessage(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        text: 'probe',
      );
      final sent = await (db.select(
        db.outboxEvents,
      )..where((t) => t.eventId.equals(eventId))).getSingle();
      await db.insertInbox(
        InboxEventsCompanion.insert(
          objectId: Value(sent.objectId!),
          eventId: eventId,
          siteId: 'site',
          roomId: 'public',
          payloadType: sent.payloadType,
          payload: Uint8List.fromList(sent.payload!),
          peerId: 'peer-b',
          receivedAtMs: 50,
        ),
      );

      final messages = await repository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .first;

      expect(messages, hasLength(1));
      expect(messages.single.mine, isTrue);
      expect(messages.single.text, 'probe');
    });
  });

  group('RoomMessageDispatcher.sendVoice', () {
    test('uses the socket when another member is reachable', () async {
      final live = _FakeLiveTransport(canReachOtherMember: true, result: true);

      final delivery = await RoomMessageDispatcher(repository, live).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(700),
        durationMs: 1800,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(delivery.eventId))).getSingle();
      expect(delivery.route, RoomMessageRoute.socket);
      expect(row.state, 'acked');
      expect(live.voiceSent.single.bytes, 700);
      expect(live.voiceSent.single.durationMs, 1800);
      expect(live.textSent, isEmpty);
    });

    test('queues for GATT when no live member is reachable', () async {
      final live = _FakeLiveTransport(canReachOtherMember: false, result: true);

      final delivery = await RoomMessageDispatcher(repository, live).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(),
        durationMs: 1000,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(delivery.eventId))).getSingle();
      expect(delivery.route, RoomMessageRoute.gatt);
      expect(row.state, RoomRepository.meshReadyState);
      expect(live.voiceSent, isEmpty);
    });

    test('promotes a failed socket send to the GATT outbox', () async {
      final live = _FakeLiveTransport(canReachOtherMember: true, result: false);

      final delivery = await RoomMessageDispatcher(repository, live).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(),
        durationMs: 1000,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(delivery.eventId))).getSingle();
      expect(delivery.route, RoomMessageRoute.gatt);
      expect(row.state, RoomRepository.meshReadyState);
      expect(live.voiceSent, hasLength(1));
    });

    test('falls back to GATT when the live transport is text-only', () async {
      final delivery = await RoomMessageDispatcher(
        repository,
        _TextOnlyTransport(),
      ).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(),
        durationMs: 1000,
      );

      final row = await (db.select(
        db.outboxEvents,
      )..where((r) => r.eventId.equals(delivery.eventId))).getSingle();
      expect(delivery.route, RoomMessageRoute.gatt);
      expect(row.state, RoomRepository.meshReadyState);
    });

    test('drains as a ROOM_VOICE envelope at bulk priority', () async {
      final submitted = Completer<MeshEnvelope>();
      final sender = OutboxSender(
        db,
        (envelope) async => submitted.complete(envelope),
        siteId: 'site',
        localEphemeralId: 7,
      )..start();
      addTearDown(sender.dispose);

      final delivery = await RoomMessageDispatcher(repository).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: _clip(1500),
        durationMs: 4000,
      );
      final envelope = await submitted.future.timeout(
        const Duration(seconds: 2),
      );

      expect(delivery.route, RoomMessageRoute.gatt);
      expect(envelope.payloadType, PayloadType.roomVoice);
      expect(envelope.priority, PriorityBand.p3Bulk);
      expect(
        RoomVoicePacketCodec.decode(
          siteId: envelope.siteId,
          roomId: envelope.roomId,
          eventId: envelope.eventId,
          packet: envelope.payload,
        ).durationMs,
        4000,
      );
    });

    test('a voice note crosses a real mesh link to a second repository', () async {
      final previousWarning =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      UniversalBlePeripheral.setInstance(_NoopPeripheral());
      final receiverDb = MeshDatabase.forTesting(NativeDatabase.memory());
      final receiverRepository = RoomRepository(receiverDb, siteId: 'site');
      final senderMesh = _meshCoordinator();
      final receiverMesh = _meshCoordinator();
      final senderLink = _PairedMeshLink();
      final receiverLink = _PairedMeshLink();
      senderLink.peer = receiverLink;
      receiverLink.peer = senderLink;
      senderMesh.attach('receiver', senderLink, siteFingerprint: 1);
      receiverMesh.attach('sender', receiverLink, siteFingerprint: 1);

      final incomingSubscription = receiverMesh.incoming.listen((received) {
        final envelope = received.envelope;
        unawaited(
          receiverDb.insertInbox(
            InboxEventsCompanion.insert(
              objectId: Value(envelope.objectId),
              eventId: envelope.eventId,
              siteId: envelope.siteId,
              roomId: envelope.roomId,
              payloadType: envelope.payloadType.name,
              payload: envelope.payload,
              peerId: received.peerId,
              receivedAtMs: received.receivedAtMs,
            ),
          ),
        );
      });
      final sender = OutboxSender(
        db,
        (envelope) async => senderMesh.send(envelope),
        siteId: 'site',
        localEphemeralId: 7,
      )..start();
      addTearDown(() async {
        await sender.dispose();
        await incomingSubscription.cancel();
        await senderMesh.stop();
        await receiverMesh.stop();
        await receiverDb.close();
        UniversalBlePeripheral.setInstance(UniversalBlePeripheralUnsupported());
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
      });

      final audio = _clip(2600);
      final received = receiverRepository
          .watch(policy: _publicPolicy, userRoles: _publicRoles)
          .firstWhere((messages) => messages.isNotEmpty);
      final delivery = await RoomMessageDispatcher(repository).sendVoice(
        policy: _publicPolicy,
        userRoles: _publicRoles,
        audio: audio,
        durationMs: 5500,
      );

      final messages = await received.timeout(const Duration(seconds: 4));
      expect(delivery.route, RoomMessageRoute.gatt);
      expect(messages.single.eventId, delivery.eventId);
      expect(messages.single.mine, isFalse);
      expect(messages.single.isVoice, isTrue);
      expect(messages.single.voice!.audio, audio);
      expect(messages.single.voice!.durationMs, 5500);
    });
  });
}
