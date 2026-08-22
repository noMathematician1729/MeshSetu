import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/mesh_bridge_client.dart';
import '../../app/providers.dart';
import '../../app/sos_delivery.dart';
import '../../core/data/database.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

/// Post-send screen for an SOS that was just queued. Replaces the old
/// three-tick checklist with a live radar of nearby mesh devices (from BLE
/// scan/connection RSSI), a distance estimate per device, and the delivery
/// state of this specific SOS as it moves through the outbox state machine.
///
/// [eventId] is optional so existing callers/tests that only want to show
/// location/mesh status (without a live database) still render correctly —
/// the delivery panel is simply omitted when it is null or no database
/// provider is available.
class EmergencyActiveScreen extends ConsumerWidget {
  const EmergencyActiveScreen({
    super.key,
    required this.locationStatus,
    required this.meshActive,
    this.eventId,
    this.delivery,
  });

  final String locationStatus;
  final bool meshActive;
  final String? eventId;

  /// Live lifecycle projection from the foreground mesh bridge. `acked` means
  /// mesh custody acknowledgement, not confirmed admin-backend delivery.
  final ValueListenable<SosDeliveryStatus>? delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meshStatus = ref.watch(meshStatusProvider);
    final listenable = delivery;
    if (listenable == null) {
      return _build(context, meshStatus, null);
    }
    return ValueListenableBuilder<SosDeliveryStatus>(
      valueListenable: listenable,
      builder: (context, status, _) => _build(context, meshStatus, status),
    );
  }

  Widget _build(
    BuildContext context,
    AsyncValue<MeshStatus> meshStatus,
    SosDeliveryStatus? deliveryStatus,
  ) {
    final palette = MeshPalette.of(context);
    final confirmed = deliveryStatus?.isRemoteConfirmed ?? false;
    final headline = deliveryStatus == null
        ? 'Emergency Active'
        : confirmed
        ? 'Emergency mesh delivery confirmed'
        : 'SOS saved · mesh relay pending';
    final subhead = deliveryStatus == null
        ? 'Help is on the way'
        : confirmed
        ? 'A nearby device has accepted custody of your SOS'
        : 'The packet is safe on this device; delivery is not confirmed yet';

    return MeshPage(
      title: 'Emergency Active',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MeshSpace.md),
          Icon(
            confirmed
                ? Icons.verified_outlined
                : Icons.emergency_share_outlined,
            color: palette.ember,
            size: 42,
          ),
          const SizedBox(height: MeshSpace.md),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: palette.ember),
          ),
          const SizedBox(height: MeshSpace.xs),
          Text(
            subhead,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: MeshSpace.lg),
          if (deliveryStatus case final status?)
            _DeliveryProjectionPanel(status: status),
          if (eventId case final id?) ...[
            if (deliveryStatus != null) const SizedBox(height: MeshSpace.md),
            _DeliveryPanel(eventId: id),
          ],
          const SizedBox(height: MeshSpace.lg),
          meshStatus.when(
            data: (status) => _ScanningPanel(
              status: status,
              meshActive: meshActive,
              locationStatus: locationStatus,
            ),
            loading: () => _ScanningPanel(
              status: MeshStatus.stopped,
              meshActive: meshActive,
              locationStatus: locationStatus,
            ),
            error: (_, _) => _ScanningPanel(
              status: MeshStatus.stopped,
              meshActive: meshActive,
              locationStatus: locationStatus,
            ),
          ),
          if (deliveryStatus?.broadcastFailed ?? false) ...[
            const SizedBox(height: MeshSpace.md),
            const MeshStatusPill(
              label:
                  'Compact BLE broadcast unavailable · durable mesh retry remains active',
              icon: Icons.warning_amber_rounded,
              tone: MeshStatusTone.critical,
            ),
          ],
          if (deliveryStatus != null && !confirmed) ...[
            const SizedBox(height: MeshSpace.md),
            Text(
              'Keep Event Mode running. This screen will update when a nearby mesh peer acknowledges the packet.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: MeshSpace.lg),
          MeshFullWidthButton(
            label: 'Return to home',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// A live UI-isolate delivery projection. This is intentionally separate from
/// the database panel: it shows the current foreground-task lifecycle, while
/// the database panel shows the durable outbox row for a specific event.
class _DeliveryProjectionPanel extends StatelessWidget {
  const _DeliveryProjectionPanel({required this.status});

  final SosDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final (label, detail, icon, tone) = switch (status.phase) {
      SosDeliveryPhase.confirmed => (
        'Mesh custody acknowledged',
        'A nearby device accepted the SOS. Admin-backend delivery is not confirmed.',
        Icons.check_circle_outline,
        MeshStatusTone.active,
      ),
      SosDeliveryPhase.broadcasting => (
        'Emergency SOS broadcasting',
        status.detail,
        Icons.bluetooth_audio,
        MeshStatusTone.active,
      ),
      SosDeliveryPhase.failed => (
        'Delivery failed',
        status.detail,
        Icons.error_outline,
        MeshStatusTone.critical,
      ),
      SosDeliveryPhase.saved || SosDeliveryPhase.queued => (
        'Waiting for a mesh peer',
        status.detail,
        Icons.hourglass_top,
        MeshStatusTone.neutral,
      ),
    };
    return MeshCard(
      tint: switch (tone) {
        MeshStatusTone.active => palette.live.withValues(alpha: 0.1),
        MeshStatusTone.critical => palette.ember.withValues(alpha: 0.08),
        MeshStatusTone.neutral => null,
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: switch (tone) {
              MeshStatusTone.active => palette.live,
              MeshStatusTone.critical => palette.ember,
              MeshStatusTone.neutral => palette.mesh,
            },
          ),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tracks this SOS's row through the outbox state machine (Bible §2.5):
/// created -> ready -> relaying -> acked|expired|failed. "acked" means a
/// nearby mesh peer sent a custody acknowledgement for this object — the
/// most concrete "delivery" signal this offline-first app can honestly show,
/// short of a confirmed admin-backend receipt.
class _DeliveryPanel extends ConsumerWidget {
  const _DeliveryPanel({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MeshDatabase? db;
    try {
      db = ref.watch(databaseProvider);
    } catch (_) {
      db = null;
    }
    if (db == null) return const SizedBox.shrink();
    return StreamBuilder<OutboxEvent?>(
      stream: db.watchEvent(eventId),
      builder: (context, snapshot) {
        final palette = MeshPalette.of(context);
        final (label, detail, icon, tone) = _deliveryPresentation(
          snapshot.data?.state,
        );
        return MeshCard(
          tint: switch (tone) {
            MeshStatusTone.active => palette.live.withValues(alpha: 0.1),
            MeshStatusTone.critical => palette.ember.withValues(alpha: 0.08),
            MeshStatusTone.neutral => null,
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: switch (tone) {
                  MeshStatusTone.active => palette.live,
                  MeshStatusTone.critical => palette.ember,
                  MeshStatusTone.neutral => palette.mesh,
                },
              ),
              const SizedBox(width: MeshSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(detail, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static (String, String, IconData, MeshStatusTone) _deliveryPresentation(
    String? state,
  ) => switch (state) {
    'ready' => (
      'Waiting for a mesh peer',
      'Your SOS is packaged and will send as soon as a device is in range.',
      Icons.hourglass_top,
      MeshStatusTone.neutral,
    ),
    'relaying' => (
      'Relaying now',
      'Handing your SOS to a nearby device over Bluetooth.',
      Icons.bluetooth_audio,
      MeshStatusTone.neutral,
    ),
    'acked' => (
      'Acknowledged by the mesh',
      'A nearby device confirmed receipt and will continue relaying it.',
      Icons.check_circle_outline,
      MeshStatusTone.active,
    ),
    'expired' => (
      'Delivery window expired',
      'No device accepted this SOS in time. It stays queued locally.',
      Icons.error_outline,
      MeshStatusTone.critical,
    ),
    'failed' => (
      'Delivery failed',
      'This SOS could not be sent. It stays queued locally for retry.',
      Icons.error_outline,
      MeshStatusTone.critical,
    ),
    _ => (
      'Securing your SOS',
      'Saving your emergency packet on this device before transmission.',
      Icons.lock_outline,
      MeshStatusTone.neutral,
    ),
  };
}

/// Live radar + device list replacing the old three-tick checklist. Devices
/// are placed at a stable pseudo-random angle (hashed from their peer ID, so
/// a given device does not jump around the dial between frames) and at a
/// radius derived from their estimated BLE distance.
class _ScanningPanel extends StatelessWidget {
  const _ScanningPanel({
    required this.status,
    required this.meshActive,
    required this.locationStatus,
  });

  final MeshStatus status;
  final bool meshActive;
  final String locationStatus;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    // Event-mode state is authoritative for the user-facing scan indicator;
    // the first foreground-task status callback may arrive slightly later.
    final scanning = meshActive;
    final peers = status.peers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeshCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    scanning ? Icons.radar : Icons.bluetooth_disabled,
                    color: scanning ? palette.mesh : palette.textMuted,
                  ),
                  const SizedBox(width: MeshSpace.sm),
                  Expanded(
                    child: Text(
                      scanning
                          ? 'Scanning for nearby devices…'
                          : 'Mesh scanning is not active',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  MeshStatusPill(
                    label: '${peers.length} nearby',
                    tone: peers.isNotEmpty
                        ? MeshStatusTone.active
                        : MeshStatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: MeshSpace.md),
              _RadarView(peers: peers, scanning: scanning, palette: palette),
              if (peers.isNotEmpty) ...[
                const SizedBox(height: MeshSpace.md),
                const Divider(height: 1),
                const SizedBox(height: MeshSpace.sm),
                for (final peer in peers) _PeerRow(peer: peer),
              ],
            ],
          ),
        ),
        const SizedBox(height: MeshSpace.md),
        MeshCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: locationStatus.toLowerCase().contains('unavailable')
                    ? palette.textMuted
                    : palette.live,
              ),
              const SizedBox(width: MeshSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationStatus,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadarView extends StatefulWidget {
  const _RadarView({
    required this.peers,
    required this.scanning,
    required this.palette,
  });

  final List<MeshPeerSnapshot> peers;
  final bool scanning;
  final MeshPalette palette;

  @override
  State<_RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<_RadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.scanning) _sweep.repeat();
  }

  @override
  void didUpdateWidget(_RadarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanning && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!widget.scanning && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) => CustomPaint(
              painter: _RadarPainter(
                peers: widget.peers,
                sweepAngle: reduceMotion ? 0 : _sweep.value * 2 * math.pi,
                scanning: widget.scanning && !reduceMotion,
                palette: widget.palette,
              ),
              child: Semantics(
                label: widget.peers.isEmpty
                    ? 'Radar: no nearby devices detected'
                    : 'Radar: ${widget.peers.length} nearby device'
                          '${widget.peers.length == 1 ? '' : 's'} detected',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.peers,
    required this.sweepAngle,
    required this.scanning,
    required this.palette,
  });

  final List<MeshPeerSnapshot> peers;
  final double sweepAngle;
  final bool scanning;
  final MeshPalette palette;

  /// Distance (meters) mapped to the outer ring of the radar. Anything
  /// farther is clamped to the edge rather than clipped off-screen.
  static const _maxRangeMeters = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final ringPaint = Paint()
      ..color = palette.hairline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final fraction in const [0.34, 0.67, 1.0]) {
      canvas.drawCircle(center, radius * fraction, ringPaint);
    }

    final crosshairPaint = Paint()
      ..color = palette.hairline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crosshairPaint,
    );

    if (scanning) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: sweepAngle,
          endAngle: sweepAngle + math.pi / 3,
          colors: [
            palette.mesh.withValues(alpha: 0.28),
            palette.mesh.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, sweepPaint);
    }

    for (final peer in peers) {
      final distance = peer.estimatedDistanceMeters ?? _maxRangeMeters * 0.85;
      final normalized = (distance / _maxRangeMeters).clamp(0.08, 1.0);
      final angle = _stableAngleFor(peer.peerId);
      final dotOffset = Offset(
        center.dx + radius * normalized * math.cos(angle),
        center.dy + radius * normalized * math.sin(angle),
      );
      final color = peer.connected ? palette.live : palette.mesh;
      canvas.drawCircle(
        dotOffset,
        6,
        Paint()..color = color.withValues(alpha: 0.22),
      );
      canvas.drawCircle(dotOffset, 4, Paint()..color = color);
    }

    canvas.drawCircle(center, 5, Paint()..color = palette.ember);
  }

  /// Deterministic angle in radians from a peer ID's hash, so a device's dot
  /// stays in the same place across repaints instead of jittering — BLE
  /// does not report bearing, only distance, so the angle itself carries no
  /// real directional meaning; it exists purely to separate dots visually.
  double _stableAngleFor(String peerId) =>
      (peerId.hashCode.abs() % 360) * math.pi / 180;

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.peers != peers ||
      oldDelegate.sweepAngle != sweepAngle ||
      oldDelegate.scanning != scanning;
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({required this.peer});

  final MeshPeerSnapshot peer;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final distance = peer.estimatedDistanceMeters;
    final shortId = peer.peerId.length > 12
        ? '${peer.peerId.substring(0, 12)}…'
        : peer.peerId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            peer.connected ? Icons.bluetooth_connected : Icons.bluetooth,
            size: 18,
            color: peer.connected ? palette.live : palette.mesh,
          ),
          const SizedBox(width: MeshSpace.sm),
          Expanded(
            child: Text(
              shortId,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: MeshSpace.sm),
          Text(
            distance == null
                ? '${peer.rssi ?? '?'} dBm'
                : '~${distance < 1 ? '<1' : distance.round()} m',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
