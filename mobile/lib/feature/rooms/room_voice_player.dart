import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Plays room voice notes one at a time.
///
/// The audio lives in the database as bytes inside an authenticated packet, and
/// `audioplayers` needs a file, so each clip is spooled to the temp directory
/// on first play and reused afterwards. Only one clip plays at a time — a
/// second [toggle] stops the first, which is what a chat thread should do.
///
/// [playingEventId] is a [ValueNotifier] so bubbles can rebuild their own
/// play/stop icon without the whole message list rebuilding.
class RoomVoicePlayer {
  RoomVoicePlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _completionSub = _player.onPlayerComplete.listen((_) {
      playingEventId.value = null;
    });
  }

  final AudioPlayer _player;
  StreamSubscription<void>? _completionSub;
  bool _disposed = false;

  /// Event id of the clip currently playing, or null when nothing is.
  final ValueNotifier<String?> playingEventId = ValueNotifier<String?>(null);

  /// Starts [audio] for [eventId], or stops it if that clip is already
  /// playing. Returns silently on playback failure — a codec the device cannot
  /// decode should not throw into the widget tree.
  Future<void> toggle(String eventId, Uint8List audio) async {
    if (_disposed) return;
    if (playingEventId.value == eventId) {
      await stop();
      return;
    }
    try {
      if (playingEventId.value != null) await _player.stop();
      final file = await _spool(eventId, audio);
      await _player.play(DeviceFileSource(file.path));
      if (_disposed) return;
      playingEventId.value = eventId;
    } catch (_) {
      playingEventId.value = null;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Already stopped or released.
    }
    if (!_disposed) playingEventId.value = null;
  }

  Future<File> _spool(String eventId, Uint8List audio) async {
    final dir = await getTemporaryDirectory();
    // Event ids are UUIDs, but a mesh-delivered id is attacker-influenced, so
    // strip anything that could escape the temp directory.
    final safeId = eventId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${dir.path}/room-voice-play-$safeId.opus');
    if (!await file.exists() || await file.length() != audio.length) {
      await file.writeAsBytes(audio, flush: true);
    }
    return file;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _completionSub?.cancel();
    _completionSub = null;
    try {
      await _player.dispose();
    } catch (_) {
      // Player already released.
    }
    playingEventId.dispose();
  }
}
