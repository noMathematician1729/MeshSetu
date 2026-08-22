import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

/// This screen lets the operator point the phone at a reachable dashboard
/// address (local Wi-Fi or an HTTPS tunnel) and flip it into gateway mode —
/// forwarding is performed by `MeshBridgeClient` when event mode is running.
/// The gateway sends encrypted mesh objects; the Node server verifies them.
class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  late final _urlController = TextEditingController(
    text: ref.read(gatewayUrlProvider),
  );
  late final _keyController = TextEditingController(
    text: ref.read(gatewayDemoKeyProvider),
  );

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(gatewayEnabledProvider);
    return MeshPage(
      title: 'Emergency Gateway',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MeshStatusPill(
            label: 'Advanced setting',
            icon: Icons.security_outlined,
          ),
          const SizedBox(height: MeshSpace.md),
          Text(
            'Enable this only on a phone that can receive Bluetooth SOS packets and reach the control room.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: MeshSpace.lg),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Dashboard base URL',
              hintText: productionBackendUrl,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => ref.read(gatewayUrlProvider.notifier).state = v,
          ),
          const SizedBox(height: MeshSpace.md),
          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Dashboard gateway key',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                ref.read(gatewayDemoKeyProvider.notifier).state = v,
          ),
          const SizedBox(height: MeshSpace.lg),
          MeshCard(
            child: Row(
              children: [
                Icon(
                  Icons.router_outlined,
                  color: MeshPalette.of(context).textMuted,
                ),
                const SizedBox(width: MeshSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Act as emergency gateway',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        enabled
                            ? 'Encrypted SOS packets are forwarded when reachable.'
                            : 'This phone remains peer-to-peer only.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) =>
                      ref.read(gatewayEnabledProvider.notifier).state = v,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
