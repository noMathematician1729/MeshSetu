import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/feature/rooms/room_voice_packet.dart';

Uint8List _audio(int length, {int seed = 3}) =>
    Uint8List.fromList(List<int>.generate(length, (i) => (i * seed + 11) % 256));

Uint8List _packet({
  String siteId = 'demo-site',
  String roomId = 'public',
  String eventId = 'event-1',
  Uint8List? audio,
  int durationMs = 2500,
  String? senderName = 'Alice',
}) => RoomVoicePacketCodec.encode(
  siteId: siteId,
  roomId: roomId,
  eventId: eventId,
  audio: audio ?? _audio(512),
  durationMs: durationMs,
  senderName: senderName,
);

void main() {
  group('RoomVoicePacketCodec', () {
    test('round-trips audio, duration, and sender name', () {
      final audio = _audio(1024);
      final content = RoomVoicePacketCodec.decode(
        siteId: 'demo-site',
        roomId: 'public',
        eventId: 'event-1',
        packet: _packet(audio: audio, durationMs: 3200),
      );

      expect(content.audio, audio);
      expect(content.durationMs, 3200);
      expect(content.senderName, 'Alice');
    });

    test('a null sender name decodes as an empty string', () {
      final content = RoomVoicePacketCodec.decode(
        siteId: 'demo-site',
        roomId: 'public',
        eventId: 'event-1',
        packet: _packet(senderName: null),
      );

      expect(content.senderName, isEmpty);
    });

    test('truncates a long sender name without splitting a rune', () {
      // 'ñ' is 2 UTF-8 bytes; 35 of them is 70 bytes, past the 64-byte field.
      final content = RoomVoicePacketCodec.decode(
        siteId: 'demo-site',
        roomId: 'public',
        eventId: 'event-1',
        packet: _packet(senderName: 'ñ' * 35),
      );

      expect(content.senderName, 'ñ' * 32);
    });

    test('framing overhead is exactly overheadBytes for an unnamed clip', () {
      final packet = _packet(audio: _audio(700), senderName: null);

      expect(packet.length, 700 + RoomVoicePacketCodec.overheadBytes);
    });

    test('isEncoded recognises its own packets and rejects other payloads', () {
      expect(RoomVoicePacketCodec.isEncoded(_packet()), isTrue);
      expect(
        RoomVoicePacketCodec.isEncoded(Uint8List.fromList(List.filled(64, 9))),
        isFalse,
      );
      // "MSRM" text-packet magic must not be mistaken for "MSRV".
      expect(
        RoomVoicePacketCodec.isEncoded(
          Uint8List.fromList([0x4D, 0x53, 0x52, 0x4D, ...List.filled(40, 0)]),
        ),
        isFalse,
      );
      expect(RoomVoicePacketCodec.isEncoded(Uint8List(4)), isFalse);
    });

    test('rejects a tampered audio byte', () {
      final packet = _packet();
      packet[RoomVoicePacketCodec.headerBytes + 5] ^= 0xFF;

      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'public',
          eventId: 'event-1',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a tampered duration', () {
      final packet = _packet(durationMs: 2000);
      // durationMs occupies bytes 7..8.
      packet[7] ^= 0x01;

      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'public',
          eventId: 'event-1',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a packet cannot be replayed into another room or event', () {
      final packet = _packet();

      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'responders',
          eventId: 'event-1',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'public',
          eventId: 'event-2',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'other-site',
          roomId: 'public',
          eventId: 'event-1',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a truncated packet', () {
      final packet = _packet();
      final truncated = Uint8List.sublistView(packet, 0, packet.length - 1);

      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'public',
          eventId: 'event-1',
          packet: truncated,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unknown version', () {
      final packet = _packet();
      packet[4] = 9;

      expect(
        () => RoomVoicePacketCodec.decode(
          siteId: 'demo-site',
          roomId: 'public',
          eventId: 'event-1',
          packet: packet,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an unknown codec or sample rate', () {
      final badCodec = _packet();
      badCodec[5] = 7;
      final badRate = _packet();
      badRate[6] = 7;

      for (final packet in [badCodec, badRate]) {
        expect(
          () => RoomVoicePacketCodec.decode(
            siteId: 'demo-site',
            roomId: 'public',
            eventId: 'event-1',
            packet: packet,
          ),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('encode refuses empty audio, oversized audio, and bad durations', () {
      expect(
        () => _packet(audio: Uint8List(0)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _packet(
          audio: _audio(RoomVoicePacketCodec.maxAudioBytes + 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => _packet(durationMs: 0), throwsA(isA<ArgumentError>()));
      expect(
        () => _packet(
          durationMs: RoomVoicePacketCodec.maxDurationMs + 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => _packet(roomId: '  '), throwsA(isA<ArgumentError>()));
    });

    test('accepts the largest clip the format allows', () {
      final audio = _audio(RoomVoicePacketCodec.maxAudioBytes);
      final content = RoomVoicePacketCodec.decode(
        siteId: 'demo-site',
        roomId: 'public',
        eventId: 'event-1',
        packet: _packet(
          audio: audio,
          durationMs: RoomVoicePacketCodec.maxDurationMs,
        ),
      );

      expect(content.audio.length, RoomVoicePacketCodec.maxAudioBytes);
      expect(content.durationMs, RoomVoicePacketCodec.maxDurationMs);
    });
  });
}
