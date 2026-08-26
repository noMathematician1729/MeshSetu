import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'room_voice_packet.dart';

/// A finished push-to-talk capture, ready to be framed by
/// [RoomVoicePacketCodec].
class RoomVoiceClip {
  const RoomVoiceClip({required this.audio, required this.durationMs});

  final Uint8List audio;
  final int durationMs;
}

/// Push-to-talk capture for room voice notes.
///
/// Separate from `feature/voice/VoiceRecorder` (SOS evidence) on purpose:
/// that recorder uses `record`'s default 128 kbps, which produces roughly
/// 160 KB for a 10-second clip — far beyond the transport's 64 KB
/// `maxObjectBytes` ceiling once the envelope is added. A room voice note has
/// to fragment across a BLE link, so this recorder pins a low bitrate and a
/// short duration cap instead.
///
/// At [bitRate] a full-length clip is about
/// `8 s × 12 kbps ÷ 8 = 12 KB`, which fragments into ~25 frames at a
/// negotiated 517-byte MTU.
class RoomVoiceRecorder {
  RoomVoiceRecorder({AudioRecorder? recorder, Duration? cap})
    : _recorder = recorder ?? AudioRecorder(),
      cap = cap ?? maxClip;

  /// Longest capture, matching [RoomVoicePacketCodec.maxDurationMs].
  static const Duration maxClip = Duration(
    milliseconds: RoomVoicePacketCodec.maxDurationMs,
  );

  /// Anything shorter than this is treated as an accidental tap rather than a
  /// voice note, so a fumbled press does not queue an empty clip on the mesh.
  static const Duration minClip = Duration(milliseconds: 400);

  /// Target Opus bitrate. Low enough that a full-length clip stays a few
  /// kilobytes; intelligible speech, audibly compressed.
  static const int bitRate = 12000;

  final AudioRecorder _recorder;
  final Duration cap;

  DateTime? _startedAt;
  DateTime? _stoppedAt;
  String? _path;
  Timer? _capTimer;
  Future<RoomVoiceClip?>? _stopping;

  bool get recording => _startedAt != null && _stopping == null;

  /// True once the duration cap ended the capture on its own.
  bool get capReached => _capReached;
  bool _capReached = false;

  /// How long the current (or just-finished) capture ran, for a live UI
  /// indicator. Frozen once the capture stops.
  Duration get elapsed {
    final startedAt = _startedAt;
    if (startedAt == null) return Duration.zero;
    final end = _stoppedAt ?? DateTime.now();
    final value = end.difference(startedAt);
    return value > cap ? cap : value;
  }

  /// Begins a capture. Throws [StateError] when the microphone permission is
  /// denied or a capture is already running.
  Future<void> start() async {
    if (_startedAt != null) {
      throw StateError('a room voice capture is already running');
    }
    if (!await _recorder.hasPermission()) {
      throw StateError('microphone permission denied');
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/room-voice-${DateTime.now().millisecondsSinceEpoch}.opus';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.opus,
        sampleRate: RoomVoicePacketCodec.sampleRateHz,
        numChannels: 1,
        bitRate: bitRate,
      ),
      path: path,
    );
    _path = path;
    _capReached = false;
    _stoppedAt = null;
    _stopping = null;
    _startedAt = DateTime.now();
    _capTimer = Timer(cap, () {
      _capReached = true;
      _stopping ??= _finish();
    });
  }

  /// Ends the capture and returns the clip, or null when nothing usable was
  /// recorded (released before [minClip], or the encoder produced no bytes).
  ///
  /// Idempotent within one press-and-release cycle: if the duration cap
  /// already stopped the capture, this returns that same clip rather than
  /// starting a second stop.
  Future<RoomVoiceClip?> stop() {
    if (_startedAt == null) return Future.value(null);
    return _stopping ??= _finish();
  }

  /// Ends the capture and discards the audio — used when the user slides off
  /// the button to abort, or the screen is disposed mid-press.
  Future<void> cancel() async {
    if (_startedAt == null) return;
    _capTimer?.cancel();
    _capTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Aborting; a stop failure has nothing left to report.
    }
    await _deleteTempFile();
    _reset();
  }

  Future<RoomVoiceClip?> _finish() async {
    _capTimer?.cancel();
    _capTimer = null;
    _stoppedAt ??= DateTime.now();
    final durationMs = elapsed.inMilliseconds;
    try {
      await _recorder.stop();
      final path = _path;
      if (path == null) return null;
      final file = File(path);
      if (!await file.exists()) return null;
      final audio = await file.readAsBytes();
      if (audio.isEmpty ||
          durationMs < minClip.inMilliseconds ||
          audio.length > RoomVoicePacketCodec.maxAudioBytes) {
        return null;
      }
      return RoomVoiceClip(
        audio: Uint8List.fromList(audio),
        durationMs: clampDurationMs(durationMs),
      );
    } finally {
      await _deleteTempFile();
      _reset();
    }
  }

  /// Clamps a measured capture length into the range the packet codec's
  /// 16-bit duration field accepts.
  static int clampDurationMs(int measured) =>
      measured.clamp(1, RoomVoicePacketCodec.maxDurationMs);

  Future<void> _deleteTempFile() async {
    final path = _path;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Temp-file cleanup is best effort; the OS clears this directory.
    }
  }

  void _reset() {
    _startedAt = null;
    _stoppedAt = null;
    _path = null;
    // _capReached is deliberately left alone so the UI can still tell that
    // the last capture ended because it hit the cap. start() clears it.
  }

  Future<void> dispose() async {
    _capTimer?.cancel();
    _capTimer = null;
    if (_startedAt != null) await cancel();
    await _recorder.dispose();
  }
}
