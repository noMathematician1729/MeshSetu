import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/ble/device_key_store.dart';
import '../../core/protocol/frame.dart';

/// Decoded content of a room voice packet.
class RoomVoiceContent {
  const RoomVoiceContent({
    required this.audio,
    required this.durationMs,
    required this.senderName,
  });

  /// Encoded audio bytes, exactly as captured by `RoomVoiceRecorder`
  /// ([RoomVoicePacketCodec.codecOpus] / [RoomVoicePacketCodec.sampleRateHz]).
  final Uint8List audio;

  /// Recorded length in milliseconds, so the UI can show a duration without
  /// decoding the audio. Advisory only — it is authenticated, but a sender
  /// could still report a value that disagrees with the real clip.
  final int durationMs;

  /// Display name of the sender, or an empty string when the sender had no
  /// profile name to attach.
  final String senderName;
}

/// Authenticated push-to-talk voice note carried inside a mesh envelope as a
/// [PayloadType.roomVoice] payload.
///
/// This is deliberately a separate format from `VoiceObjectPayload` (SOS
/// evidence), which is base64-inside-JSON: that representation inflates audio
/// by ~33%, and a room voice note has a much tighter byte budget than an SOS
/// clip because it must fragment across a BLE link. The layout here is binary
/// and adds 25 bytes of framing plus the sender name.
///
/// ## Wire layout (v1)
///
/// ```text
/// [magic:4]["MSRV"]
/// [version:1][=1]
/// [codec:1][=1 opus]
/// [sampleRateCode:1][=1 → 16 kHz]
/// [durationMs:2 BE]
/// [senderNameLength:1]
/// [audioLength:4 BE]
/// [utf8SenderName][audio]
/// [hmac:16]
/// ```
///
/// The HMAC is a 128-bit truncated HMAC-SHA256 over the NUL-delimited
/// `siteId\0roomId\0eventId\0` context followed by every header and body
/// byte, matching `RoomMessagePacketCodec` exactly — so the version, codec,
/// duration, name, and audio are all authenticated, and a packet cannot be
/// replayed into a different room or under a different event id. The mesh's
/// AES-GCM object authentication still applies on top of this.
abstract final class RoomVoicePacketCodec {
  static const List<int> _magic = [0x4D, 0x53, 0x52, 0x56]; // "MSRV"
  static const int _version = 1;

  /// Opus in an Ogg container, as produced by `record`'s Opus encoder.
  static const int codecOpus = 1;

  static const int _sampleRateCode16k = 1;

  /// Capture sample rate the [codecOpus] audio is expected to use.
  static const int sampleRateHz = 16000;

  // magic(4) + version(1) + codec(1) + sampleRate(1) + durationMs(2)
  // + nameLength(1) + audioLength(4) = 14
  static const int headerBytes = 14;
  static const int _tagBytes = 16;

  /// Framing cost of an empty-name packet: header plus HMAC.
  static const int overheadBytes = headerBytes + _tagBytes;

  /// Maximum UTF-8 byte length of the sender name, matching
  /// `RoomMessagePacketCodec.maxSenderNameBytes`.
  static const int maxSenderNameBytes = 64;

  /// Longest clip [encode] will accept. Chosen so a packet can never exceed
  /// the transport's [maxObjectBytes] ceiling even before the AES-GCM
  /// envelope is added: `RoomVoiceRecorder` targets ~12 kbps, so 8 seconds is
  /// roughly 12 KB and this leaves a wide margin for encoder overshoot.
  static const int maxDurationMs = 8000;

  /// Hard ceiling on the audio field. Half of [maxObjectBytes] leaves room
  /// for the protobuf envelope and AEAD expansion around the packet.
  static const int maxAudioBytes = maxObjectBytes ~/ 2;

  /// Encodes a v1 packet. Throws [ArgumentError] when the ids are blank, the
  /// audio is empty or beyond [maxAudioBytes], or [durationMs] is outside
  /// `1..maxDurationMs`.
  static Uint8List encode({
    required String siteId,
    required String roomId,
    required String eventId,
    required Uint8List audio,
    required int durationMs,
    String? senderName,
  }) {
    if (siteId.trim().isEmpty ||
        roomId.trim().isEmpty ||
        eventId.trim().isEmpty) {
      throw ArgumentError('site, room, and event ids must not be blank');
    }
    if (audio.isEmpty || audio.length > maxAudioBytes) {
      throw ArgumentError('voice audio must be 1..$maxAudioBytes bytes');
    }
    if (durationMs < 1 || durationMs > maxDurationMs) {
      throw ArgumentError('voice duration must be 1..${maxDurationMs}ms');
    }
    final nameBytes = _truncateUtf8(senderName ?? '', maxSenderNameBytes);

    final headerAndBody = Uint8List(
      headerBytes + nameBytes.length + audio.length,
    );
    headerAndBody.setRange(0, _magic.length, _magic);
    headerAndBody[4] = _version;
    headerAndBody[5] = codecOpus;
    headerAndBody[6] = _sampleRateCode16k;
    final view = ByteData.sublistView(headerAndBody);
    view.setUint16(7, durationMs, Endian.big);
    headerAndBody[9] = nameBytes.length;
    view.setUint32(10, audio.length, Endian.big);
    headerAndBody.setRange(headerBytes, headerBytes + nameBytes.length, nameBytes);
    headerAndBody.setRange(headerBytes + nameBytes.length, headerAndBody.length, audio);

    final tag = _tag(
      siteId: siteId,
      roomId: roomId,
      eventId: eventId,
      packetWithoutTag: headerAndBody,
    );
    return Uint8List.fromList([...headerAndBody, ...tag]);
  }

  /// Returns true when [packet] starts with the MSRV magic and is long enough
  /// to plausibly be a room voice packet. Used to tell a voice payload apart
  /// from a text payload without attempting a full authenticated decode.
  static bool isEncoded(Uint8List packet) =>
      packet.length >= overheadBytes &&
      _constantTimeEquals(
        Uint8List.sublistView(packet, 0, _magic.length),
        Uint8List.fromList(_magic),
      );

  /// Decodes and authenticates a packet.
  ///
  /// Throws [FormatException] when the packet is not a room voice packet,
  /// carries an unknown version or codec, has an inconsistent length, or
  /// fails the HMAC check.
  static RoomVoiceContent decode({
    required String siteId,
    required String roomId,
    required String eventId,
    required Uint8List packet,
  }) {
    if (!isEncoded(packet)) {
      throw const FormatException('not a MeshSetu room-voice packet');
    }
    if (packet[4] != _version) {
      throw const FormatException('unsupported room-voice packet version');
    }
    if (packet[5] != codecOpus || packet[6] != _sampleRateCode16k) {
      throw const FormatException('unsupported room-voice audio format');
    }
    final view = ByteData.sublistView(packet);
    final durationMs = view.getUint16(7, Endian.big);
    final nameLength = packet[9];
    final audioLength = view.getUint32(10, Endian.big);
    if (durationMs < 1 ||
        durationMs > maxDurationMs ||
        nameLength > maxSenderNameBytes ||
        audioLength < 1 ||
        audioLength > maxAudioBytes ||
        packet.length != headerBytes + nameLength + audioLength + _tagBytes) {
      throw const FormatException('invalid room-voice packet length');
    }
    final nameStart = headerBytes;
    final audioStart = nameStart + nameLength;
    final bodyEnd = audioStart + audioLength;

    final expectedTag = _tag(
      siteId: siteId,
      roomId: roomId,
      eventId: eventId,
      packetWithoutTag: Uint8List.sublistView(packet, 0, bodyEnd),
    );
    if (!_constantTimeEquals(
      expectedTag,
      Uint8List.sublistView(packet, bodyEnd),
    )) {
      throw const FormatException('room-voice HMAC mismatch');
    }

    return RoomVoiceContent(
      audio: Uint8List.fromList(
        Uint8List.sublistView(packet, audioStart, bodyEnd),
      ),
      durationMs: durationMs,
      senderName: nameLength == 0
          ? ''
          : utf8.decode(
              Uint8List.sublistView(packet, nameStart, audioStart),
              allowMalformed: false,
            ),
    );
  }

  static Uint8List _tag({
    required String siteId,
    required String roomId,
    required String eventId,
    required Uint8List packetWithoutTag,
  }) {
    final context = utf8.encode('$siteId\u0000$roomId\u0000$eventId\u0000');
    final digest = Hmac(
      sha256,
      SiteKeyProvisioning.demoKey(siteId),
    ).convert(<int>[...context, ...packetWithoutTag]);
    return Uint8List.fromList(digest.bytes.sublist(0, _tagBytes));
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  /// UTF-8 encoding of [value] truncated to at most [maxBytes] without
  /// splitting a multi-byte character.
  static Uint8List _truncateUtf8(String value, int maxBytes) {
    final encoded = utf8.encode(value);
    if (encoded.length <= maxBytes) return Uint8List.fromList(encoded);
    var end = maxBytes;
    while (end > 0 && (encoded[end] & 0xC0) == 0x80) {
      end--;
    }
    return Uint8List.fromList(encoded.sublist(0, end));
  }
}
