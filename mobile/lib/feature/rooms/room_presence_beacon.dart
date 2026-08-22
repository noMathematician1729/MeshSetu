import 'dart:async';

/// Keeps this device on other phones' room member lists.
///
/// Room membership is derived from `responderUpdate` presence packets that
/// travel the same store-and-forward path as chat messages, so a single
/// announcement made when a screen opens is easy to lose: if no peer is
/// connected at that moment, nobody learns this device joined, and the member
/// list stays empty on both sides even though both users are "in" the room.
///
/// This beacon closes that gap in the two ways that matter offline:
/// * a periodic re-announce while a room screen is open, and
/// * an immediate re-announce when the mesh gains a peer, which is exactly
///   the moment a fresh presence packet can actually be delivered.
///
/// It holds no BLE or Riverpod references — [announce] and the peer-count
/// stream are injected — so the timing rules are unit-testable without a
/// radio or a widget tree.
class RoomPresenceBeacon {
  RoomPresenceBeacon({
    required this.announce,
    required this.peerCounts,
    this.interval = const Duration(seconds: 60),
  });

  /// Enqueues one presence announcement for the room.
  final Future<void> Function() announce;

  /// Live mesh peer counts; a rising value is the cue to re-announce.
  final Stream<int> peerCounts;

  /// Re-announce cadence while the room is open. Presence rows carry a 24h
  /// TTL, so this is about reaching peers that connect later, not refreshing
  /// an expiring record.
  final Duration interval;

  Timer? _timer;
  StreamSubscription<int>? _peerSubscription;
  int _lastPeerCount = 0;
  var _started = false;
  var _disposed = false;

  /// Announces immediately, then keeps announcing on [interval] and whenever
  /// the peer count rises.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_safeAnnounce());
    _timer = Timer.periodic(interval, (_) => unawaited(_safeAnnounce()));
    _peerSubscription = peerCounts.listen((count) {
      final gainedPeer = count > _lastPeerCount;
      _lastPeerCount = count;
      // Announce on the rising edge only. A steady connection does not need a
      // packet per status update, and a dropped peer cannot receive one.
      if (gainedPeer) unawaited(_safeAnnounce());
    });
  }

  Future<void> _safeAnnounce() async {
    if (_disposed) return;
    try {
      await announce();
    } catch (_) {
      // Presence is best-effort: the next tick or the next peer that connects
      // retries, and a failed announce must never break the room UI.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    await _peerSubscription?.cancel();
    _peerSubscription = null;
  }
}
