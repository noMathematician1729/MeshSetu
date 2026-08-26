import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/core/protocol/frame.dart';
import 'package:meshsetu_mobile/feature/rooms/room_voice_capacity.dart';

void main() {
  group('RoomVoiceCapacity', () {
    test('the ATT default MTU has a 2 KB object budget', () {
      // maxFragmentPayload(23) is 4 bytes; 4 * 512 chunks = 2048.
      expect(RoomVoiceCapacity.maxObjectBytesForMtu(23), 2048);
    });

    test('a negotiated MTU is capped by the transport object ceiling', () {
      // 517 gives 496 bytes per frame, so the chunk budget (253 KB) exceeds
      // maxObjectBytes and the ceiling wins.
      expect(RoomVoiceCapacity.maxObjectBytesForMtu(517), maxObjectBytes);
      expect(RoomVoiceCapacity.maxObjectBytesForMtu(247), maxObjectBytes);
    });

    test('packet budget subtracts envelope overhead and never goes negative', () {
      expect(
        RoomVoiceCapacity.maxPacketBytesForMtu(517),
        maxObjectBytes - RoomVoiceCapacity.envelopeOverheadBytes,
      );
      // 2048 - 320 overhead leaves 1728 at the default MTU.
      expect(RoomVoiceCapacity.maxPacketBytesForMtu(23), 1728);
      expect(RoomVoiceCapacity.maxPacketBytesForMtu(0), greaterThanOrEqualTo(0));
    });

    test('canCarryPacket tracks the per-MTU budget', () {
      expect(RoomVoiceCapacity.canCarryPacket(23, 1728), isTrue);
      expect(RoomVoiceCapacity.canCarryPacket(23, 1729), isFalse);
      expect(RoomVoiceCapacity.canCarryPacket(517, 12000), isTrue);
      expect(RoomVoiceCapacity.canCarryPacket(517, 0), isFalse);
    });

    test('a clip is allowed when any single peer can carry it', () {
      expect(RoomVoiceCapacity.anyPeerCanCarry([23, 517], 12000), isTrue);
      expect(RoomVoiceCapacity.anyPeerCanCarry([23, 30], 12000), isFalse);
      expect(RoomVoiceCapacity.anyPeerCanCarry(const [], 12000), isFalse);
    });

    group('blockedReason', () {
      test('does not block when there are no connected peers', () {
        // Matches how room text behaves: queue in the durable outbox and wait
        // for a peer rather than refusing to compose.
        expect(
          RoomVoiceCapacity.blockedReason(
            connectedPeerMtus: const [],
            packetBytes: 12000,
          ),
          isNull,
        );
      });

      test('does not block when a capable peer is connected', () {
        expect(
          RoomVoiceCapacity.blockedReason(
            connectedPeerMtus: const [23, 517],
            packetBytes: 12000,
          ),
          isNull,
        );
      });

      test('explains the shortfall when every peer link is too narrow', () {
        final reason = RoomVoiceCapacity.blockedReason(
          connectedPeerMtus: const [23],
          packetBytes: 12000,
        );

        expect(reason, isNotNull);
        expect(reason, contains('11.7 KB'));
        expect(reason, contains('1.7 KB'));
      });

      test('the budget never collapses to zero, even below the ATT default', () {
        // maxFragmentPayload floors the usable ATT value at 20 bytes, so the
        // smallest possible budget is still 2 KB minus envelope overhead.
        final reason = RoomVoiceCapacity.blockedReason(
          connectedPeerMtus: const [20],
          packetBytes: 12000,
        );

        expect(RoomVoiceCapacity.maxPacketBytesForMtu(20), 1728);
        expect(reason, contains('only carry 1.7 KB'));
      });
    });
  });
}
