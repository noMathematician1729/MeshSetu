import 'dart:math' as math;

import '../../core/protocol/frame.dart';

/// Answers "can this BLE link actually carry a voice note?" before one is
/// queued.
///
/// The transport is not forgiving here. `MeshTransportCoordinator` catches the
/// [ArgumentError] that `fragment()` throws for an object too large for a
/// peer's MTU budget and calls `relay.defer()`, recording a `deferred_mtu`
/// metric. A deferred object is removed from the relay's known set, so the
/// durable outbox row stays in `relaying` and never acks: the clip disappears
/// with no user-visible error. Room text can never hit this because
/// `RoomPolicy.maxMessageBytes` is 512, but a multi-kilobyte voice note can,
/// so the UI has to check before recording rather than discover it after.
///
/// The budget is `maxFragmentPayload(mtu) × maxChunks`, capped by the
/// transport's own [maxObjectBytes] ceiling. At the ATT default MTU of 23 that
/// is only 4 bytes per frame × 512 frames = 2 KB; at a negotiated 517 it is
/// 496 × 512, well past the 64 KB cap.
abstract final class RoomVoiceCapacity {
  /// Bytes added around a room voice packet before it is fragmented: the
  /// protobuf `MeshEnvelope` fields (event/site/room ids, timestamps, hop
  /// counters, a 16-byte trace id) plus `AeadEnvelope`'s
  /// `[version:1][siteIdLen:2][siteId][iv:12][tag:16]` framing.
  ///
  /// Measured envelopes land near 200 bytes for UUID event ids and short
  /// site/room ids; 320 is a deliberate over-estimate so the gate errs toward
  /// refusing a clip that would have just fit rather than accepting one that
  /// silently stalls.
  static const int envelopeOverheadBytes = 320;

  /// Largest encrypted object a peer at [mtu] can be sent.
  static int maxObjectBytesForMtu(int mtu) =>
      math.min(maxFragmentPayload(mtu) * maxChunks, maxObjectBytes);

  /// Largest room voice packet that fits once envelope framing is accounted
  /// for. Zero when the link cannot carry a useful packet at all.
  static int maxPacketBytesForMtu(int mtu) =>
      math.max(maxObjectBytesForMtu(mtu) - envelopeOverheadBytes, 0);

  /// Whether a peer at [mtu] can carry a [packetBytes]-byte voice packet.
  static bool canCarryPacket(int mtu, int packetBytes) =>
      packetBytes > 0 && packetBytes <= maxPacketBytesForMtu(mtu);

  /// Whether any peer in [connectedPeerMtus] can carry [packetBytes].
  static bool anyPeerCanCarry(
    Iterable<int> connectedPeerMtus,
    int packetBytes,
  ) => connectedPeerMtus.any((mtu) => canCarryPacket(mtu, packetBytes));

  /// A human-readable reason a voice note cannot be sent right now, or null
  /// when sending should be allowed.
  ///
  /// An empty [connectedPeerMtus] is deliberately *not* a blocker: room text
  /// behaves the same way, queueing in the durable outbox until a peer
  /// appears. Only a link that is present and demonstrably too narrow blocks,
  /// because that is the case that would stall invisibly.
  static String? blockedReason({
    required Iterable<int> connectedPeerMtus,
    required int packetBytes,
  }) {
    final mtus = connectedPeerMtus.toList(growable: false);
    if (mtus.isEmpty) return null;
    if (anyPeerCanCarry(mtus, packetBytes)) return null;
    // `maxFragmentPayload` floors the usable ATT value at 20 bytes, so even
    // the ATT default MTU yields a 2 KB object budget — the remaining budget
    // is always positive and only ever too small, never zero.
    final budget = maxPacketBytesForMtu(mtus.reduce(math.max));
    return 'Voice note is ${_kb(packetBytes)} but the Bluetooth link can '
        'only carry ${_kb(budget)}. Record a shorter note, or send text.';
  }

  static String _kb(int bytes) => bytes < 1024
      ? '$bytes B'
      : '${(bytes / 1024).toStringAsFixed(1)} KB';
}
