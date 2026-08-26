import 'dart:typed_data';

import 'room_policy.dart';
import 'room_presence_socket.dart';
import 'room_repository.dart';

enum RoomMessageRoute { socket, gatt }

class RoomMessageDelivery {
  const RoomMessageDelivery({required this.eventId, required this.route});

  final String eventId;
  final RoomMessageRoute route;
}

/// Chooses one transport for a room message while retaining the message in
/// Drift until the chosen path has accepted it. A joined socket with another
/// online room member is preferred; every other case enters the durable GATT
/// outbox used by the foreground mesh service.
class RoomMessageDispatcher {
  const RoomMessageDispatcher(this.repository, [this.liveTransport]);

  final RoomRepository repository;
  final LiveRoomMessageTransport? liveTransport;

  Future<RoomMessageDelivery> send({
    required RoomPolicy policy,
    required Set<String> userRoles,
    required String text,
  }) async {
    final live = liveTransport;
    final trySocket = live?.canReachOtherMember ?? false;
    final eventId = await repository.sendMessage(
      policy: policy,
      userRoles: userRoles,
      text: text,
      initialState: trySocket
          ? RoomRepository.socketPendingState
          : RoomRepository.meshReadyState,
    );

    if (!trySocket) {
      return RoomMessageDelivery(
        eventId: eventId,
        route: RoomMessageRoute.gatt,
      );
    }

    final delivered = await live!.sendRoomMessage(
      messageId: eventId,
      text: text.trim(),
    );
    if (delivered) {
      await repository.markSocketDelivered(eventId);
      return RoomMessageDelivery(
        eventId: eventId,
        route: RoomMessageRoute.socket,
      );
    }

    await repository.queueForMesh(eventId);
    return RoomMessageDelivery(eventId: eventId, route: RoomMessageRoute.gatt);
  }

  /// Same socket-first-then-GATT choice as [send], for a push-to-talk voice
  /// note. The clip is always written to the durable outbox first, so a failed
  /// socket attempt degrades to the mesh instead of losing the recording.
  ///
  /// The voice transport is derived from [liveTransport] with a type check
  /// rather than taken as a second constructor argument: [RoomPresenceSocket]
  /// implements both interfaces, and this keeps the existing constructor
  /// signature — and every fake built against it — unchanged.
  Future<RoomMessageDelivery> sendVoice({
    required RoomPolicy policy,
    required Set<String> userRoles,
    required Uint8List audio,
    required int durationMs,
  }) async {
    final live = liveTransport;
    final voice = live is LiveRoomVoiceTransport ? live : null;
    final trySocket = voice?.canReachOtherMember ?? false;
    final eventId = await repository.sendVoiceMessage(
      policy: policy,
      userRoles: userRoles,
      audio: audio,
      durationMs: durationMs,
      initialState: trySocket
          ? RoomRepository.socketPendingState
          : RoomRepository.meshReadyState,
    );

    if (!trySocket) {
      return RoomMessageDelivery(
        eventId: eventId,
        route: RoomMessageRoute.gatt,
      );
    }

    final delivered = await voice!.sendRoomVoice(
      messageId: eventId,
      audio: audio,
      durationMs: durationMs,
    );
    if (delivered) {
      await repository.markSocketDelivered(eventId);
      return RoomMessageDelivery(
        eventId: eventId,
        route: RoomMessageRoute.socket,
      );
    }

    await repository.queueForMesh(eventId);
    return RoomMessageDelivery(eventId: eventId, route: RoomMessageRoute.gatt);
  }
}
