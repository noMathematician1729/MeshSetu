import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/sos_delivery.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

class EmergencyActiveScreen extends StatelessWidget {
  const EmergencyActiveScreen({
    super.key,
    required this.locationStatus,
    required this.meshActive,
    this.delivery,
  });

  final String locationStatus;
  final bool meshActive;

  /// A live cross-isolate delivery projection. When omitted, the legacy
  /// constructor behavior remains available for isolated visual tests, while
  /// the homepage always supplies this value for an honest lifecycle.
  final ValueListenable<SosDeliveryStatus>? delivery;

  @override
  Widget build(BuildContext context) {
    final listenable = delivery;
    if (listenable == null) return _build(context, null);
    return ValueListenableBuilder<SosDeliveryStatus>(
      valueListenable: listenable,
      builder: (context, status, _) => _build(context, status),
    );
  }

  Widget _build(BuildContext context, SosDeliveryStatus? status) {
    final palette = MeshPalette.of(context);
    final legacy = status == null;
    final confirmed = status?.isRemoteConfirmed ?? meshActive;
    final phase = status?.phase;
    final progress = switch (phase) {
      SosDeliveryPhase.confirmed => 1.0,
      SosDeliveryPhase.broadcasting => 0.65,
      SosDeliveryPhase.failed => 0.35,
      SosDeliveryPhase.saved || SosDeliveryPhase.queued => 0.3,
      null => 1.0,
    };
    final headline = legacy
        ? 'Emergency Active'
        : confirmed
        ? 'Emergency mesh delivery confirmed'
        : 'SOS saved · mesh relay pending';
    final subhead = legacy
        ? 'Help is on the way'
        : confirmed
        ? 'A nearby device has accepted custody of your SOS'
        : 'The packet is safe on this device; delivery is not confirmed yet';
    final meshTitle = legacy
        ? (meshActive
              ? 'Emergency mesh connected'
              : 'Queued for emergency mesh')
        : confirmed
        ? 'Emergency mesh delivery confirmed'
        : phase == SosDeliveryPhase.broadcasting
        ? 'Emergency SOS broadcasting'
        : 'Queued for emergency mesh';
    final meshDetail = legacy
        ? (meshActive
              ? 'Nearby devices can relay your alert'
              : 'Delivery resumes when Event Mode is available')
        : status.detail;

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
          const SizedBox(height: MeshSpace.xl),
          Row(
            children: [
              Text(
                legacy ? 'Emergency protocol' : 'Delivery lifecycle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                legacy
                    ? '100%'
                    : confirmed
                    ? '100%'
                    : phase == SosDeliveryPhase.broadcasting
                    ? '65%'
                    : 'Queued',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: MeshSpace.sm),
          LinearProgressIndicator(value: progress, color: palette.ember),
          const SizedBox(height: MeshSpace.lg),
          MeshCard(
            child: Column(
              children: [
                MeshEmergencyStep(
                  title: 'Emergency packet secured',
                  detail: legacy
                      ? 'Saved locally before transmission'
                      : 'Encrypted packet saved locally before transmission',
                  complete: true,
                ),
                const Divider(),
                MeshEmergencyStep(
                  title: meshTitle,
                  detail: meshDetail,
                  complete: confirmed,
                ),
                const Divider(),
                MeshEmergencyStep(
                  title: 'Location attached',
                  detail: status?.locationStatus ?? locationStatus,
                  complete: !(status?.locationStatus ?? locationStatus)
                      .toLowerCase()
                      .contains('unavailable'),
                ),
              ],
            ),
          ),
          if (status?.broadcastFailed ?? false) ...[
            const SizedBox(height: MeshSpace.md),
            const MeshStatusPill(
              label:
                  'Compact BLE broadcast unavailable · durable mesh retry remains active',
              icon: Icons.warning_amber_rounded,
              tone: MeshStatusTone.critical,
            ),
          ],
          if (!legacy && !confirmed) ...[
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
