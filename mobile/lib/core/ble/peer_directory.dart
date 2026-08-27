import 'dart:collection';

final class PeerDirectoryEntry {
  const PeerDirectoryEntry({
    required this.ephemeralNodeId,
    required this.peerId,
    required this.mtu,
    required this.lastSeenMs,
    required this.siteFingerprint,
    this.rssi,
  });

  final int ephemeralNodeId;

  /// Short-lived BLE connection hint only. It is never used as the route key
  /// and is never emitted as production telemetry.
  final String peerId;
  final int mtu;
  final int lastSeenMs;
  final int siteFingerprint;
  final int? rssi;
}

/// Maps HELLO ephemeral IDs to current sessions. Connection/session objects are
/// deliberately not persisted: after process death they are invalid and must
/// be relearned through HELLO.
final class PeerDirectory {
  final Map<int, PeerDirectoryEntry> _byEphemeral = {};
  final Map<String, int> _byPeerId = {};

  void register({
    required int ephemeralNodeId,
    required String peerId,
    required int mtu,
    required int lastSeenMs,
    required int siteFingerprint,
    int? rssi,
  }) {
    final previousForEphemeral = _byEphemeral[ephemeralNodeId];
    if (previousForEphemeral != null && previousForEphemeral.peerId != peerId) {
      _byPeerId.remove(previousForEphemeral.peerId);
    }
    final previousEphemeral = _byPeerId[peerId];
    if (previousEphemeral != null && previousEphemeral != ephemeralNodeId) {
      _byEphemeral.remove(previousEphemeral);
    }
    final entry = PeerDirectoryEntry(
      ephemeralNodeId: ephemeralNodeId,
      peerId: peerId,
      mtu: mtu,
      lastSeenMs: lastSeenMs,
      siteFingerprint: siteFingerprint,
      rssi: rssi,
    );
    _byEphemeral[ephemeralNodeId] = entry;
    _byPeerId[peerId] = ephemeralNodeId;
  }

  void markSeen(String peerId, {required int nowMs, int? mtu, int? rssi}) {
    final ephemeral = _byPeerId[peerId];
    if (ephemeral == null) return;
    final current = _byEphemeral[ephemeral];
    if (current == null) return;
    _byEphemeral[ephemeral] = PeerDirectoryEntry(
      ephemeralNodeId: current.ephemeralNodeId,
      peerId: current.peerId,
      mtu: mtu ?? current.mtu,
      lastSeenMs: nowMs,
      siteFingerprint: current.siteFingerprint,
      rssi: rssi ?? current.rssi,
    );
  }

  PeerDirectoryEntry? entryFor(int ephemeralNodeId) =>
      _byEphemeral[ephemeralNodeId];

  PeerDirectoryEntry? entryForPeer(String peerId) {
    final ephemeral = _byPeerId[peerId];
    return ephemeral == null ? null : _byEphemeral[ephemeral];
  }

  String? peerIdFor(int ephemeralNodeId) =>
      _byEphemeral[ephemeralNodeId]?.peerId;

  List<PeerDirectoryEntry> readyPeers() =>
      UnmodifiableListView(_byEphemeral.values.toList());

  void removePeer(String peerId) {
    final ephemeral = _byPeerId.remove(peerId);
    if (ephemeral != null) _byEphemeral.remove(ephemeral);
  }

  void clear() {
    _byEphemeral.clear();
    _byPeerId.clear();
  }
}
