import 'package:flutter/material.dart';

import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

class EmergencyActiveScreen extends StatelessWidget {
  const EmergencyActiveScreen({
    super.key,
    required this.locationStatus,
    required this.meshActive,
  });

  final String locationStatus;
  final bool meshActive;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return MeshPage(
      title: 'Emergency Active',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MeshSpace.md),
          Icon(Icons.emergency_share_outlined, color: palette.ember, size: 42),
          const SizedBox(height: MeshSpace.md),
          Text(
            'Emergency Active',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: palette.ember),
          ),
          const SizedBox(height: MeshSpace.xs),
          Text(
            'Help is on the way',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: MeshSpace.xl),
          Row(
            children: [
              Text(
                'Emergency protocol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('100%', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: MeshSpace.sm),
          LinearProgressIndicator(value: 1, color: palette.ember),
          const SizedBox(height: MeshSpace.lg),
          MeshCard(
            child: Column(
              children: [
                const MeshEmergencyStep(
                  title: 'Emergency packet secured',
                  detail: 'Saved locally before transmission',
                  complete: true,
                ),
                const Divider(),
                MeshEmergencyStep(
                  title: meshActive
                      ? 'Emergency mesh connected'
                      : 'Queued for emergency mesh',
                  detail: meshActive
                      ? 'Nearby devices can relay your alert'
                      : 'Delivery resumes when Event Mode is available',
                  complete: meshActive,
                ),
                const Divider(),
                MeshEmergencyStep(
                  title: 'Location attached',
                  detail: locationStatus,
                  complete: !locationStatus.toLowerCase().contains(
                    'unavailable',
                  ),
                ),
              ],
            ),
          ),
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
