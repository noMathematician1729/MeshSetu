import 'package:flutter/material.dart';

import '../../core/ble/sos_advertisement.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

/// Recipient-facing view for the information available in a compact BLE SOS.
/// The packet intentionally excludes identity, contacts, and precise location.
class CompactSosPacketScreen extends StatelessWidget {
  const CompactSosPacketScreen({super.key, required this.alert});

  final MeshSosAdvertisement alert;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final sender = alert.hasReporterUid
        ? 'CEAL ID ${alert.reporterUidHex.toUpperCase()}'
        : 'Anonymous mesh sender';
    final packet =
        '${alert.originId.toRadixString(16).padLeft(8, '0').toUpperCase()}-${alert.sequence.toString().padLeft(5, '0')}';
    return MeshPage(
      title: 'SOS Packet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeshCard(
            tint: palette.ember.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.sos, color: palette.ember, size: 32),
                const SizedBox(width: MeshSpace.md),
                Expanded(
                  child: Text(
                    alert.emergencyType.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          MeshCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MeshDataRow(
                  label: 'Sender',
                  value: sender,
                  icon: Icons.badge_outlined,
                ),
                const Divider(height: MeshSpace.md),
                MeshDataRow(
                  label: 'Packet',
                  value: packet,
                  icon: Icons.tag_outlined,
                ),
                const Divider(height: MeshSpace.md),
                MeshDataRow(
                  label: 'Mesh relay',
                  value: alert.ttl == 1
                      ? '1 hop remaining'
                      : '${alert.ttl} hops remaining',
                  icon: Icons.bluetooth_connected,
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          const MeshCard(
            child: Text(
              'This compact SOS is safe to relay without internet. '
              'Name, emergency contacts, and precise location are encrypted. '
              'When the control room resolves the packet, this notification '
              'updates to the full incident details.',
            ),
          ),
        ],
      ),
    );
  }
}
