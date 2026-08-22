import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/emergency_gestures.dart';
import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../../ui/theme/theme_controller.dart';
import '../gateway/gateway_screen.dart';
import 'gesture_mappings_screen.dart';
import '../location/location_screen.dart';

/// Fix for a pre-existing rendering issue (flagged in Task 3): the previous
/// version of this screen placed `ListTile`/`SwitchListTile` rows directly
/// inside `MeshCard`'s `DecoratedBox`, with no intervening `Material`
/// ancestor. Flutter's framework asserts "ListTile background color or ink
/// splashes may be invisible" in that configuration. This rewrite drops
/// `ListTile` entirely in favor of plain `Row`-based layouts (the same
/// pattern `room_lobby_screen.dart`'s member rows already use), so no
/// `Material` wrapper is needed.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);
    final timeout = ref.watch(sosTimeoutProvider);
    return MeshPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MeshSectionTitle('Accessibility'),
          MeshCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingRow(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  trailing: const Text('English'),
                ),
                const Divider(height: MeshSpace.sm),
                Text(
                  'Font size: ${(fontScale * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  min: .85,
                  max: 1.35,
                  divisions: 5,
                  value: fontScale,
                  label: '${(fontScale * 100).round()}%',
                  onChanged: (value) =>
                      ref.read(fontScaleProvider.notifier).state = value,
                ),
                _SwitchRow(
                  icon: Icons.contrast_outlined,
                  title: 'High contrast mode',
                  value: ref.watch(highContrastProvider),
                  onChanged: (value) =>
                      ref.read(highContrastProvider.notifier).state = value,
                ),
                const Divider(height: MeshSpace.sm),
                _SwitchRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  value: ref.watch(darkModeProvider),
                  onChanged: (value) =>
                      ref.read(darkModeProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.lg),
          const MeshSectionTitle('Emergency settings'),
          MeshCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SOS hold time: ${timeout.round()} seconds',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  min: 2,
                  max: 5,
                  divisions: 3,
                  value: timeout,
                  label: '${timeout.round()} seconds',
                  onChanged: (value) =>
                      ref.read(sosTimeoutProvider.notifier).state = value,
                ),
                _SwitchRow(
                  icon: Icons.location_on_outlined,
                  title: 'Attach location to SOS',
                  value: ref.watch(locationSharingProvider),
                  onChanged: (value) =>
                      ref.read(locationSharingProvider.notifier).state = value,
                ),
                const Divider(height: MeshSpace.sm),
                _NavRow(
                  icon: Icons.map_outlined,
                  title: 'Location details',
                  subtitle: 'GPS accuracy and manual address',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LocationScreen()),
                  ),
                ),
                const Divider(height: MeshSpace.sm),
                _NavRow(
                  icon: Icons.tune_outlined,
                  title: 'Reprogram gestures',
                  subtitle: 'Set unique 2–5 press volume-button sequences',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GestureMappingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: MeshSpace.sm),
                const _GestureRow(),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.lg),
          const MeshSectionTitle('Connectivity'),
          MeshCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GatewayScreen())),
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
                        'Emergency gateway',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Configure control-room forwarding',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.sm),
          MeshStatusPill(
            label: ref.watch(gatewayEnabledProvider)
                ? 'Gateway forwarding enabled'
                : 'Gateway forwarding disabled',
            tone: ref.watch(gatewayEnabledProvider)
                ? MeshStatusTone.active
                : MeshStatusTone.neutral,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
    child: Row(
      children: [
        Icon(icon, color: MeshPalette.of(context).textMuted),
        const SizedBox(width: MeshSpace.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        trailing,
      ],
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
    child: Row(
      children: [
        Icon(icon, color: MeshPalette.of(context).textMuted),
        const SizedBox(width: MeshSpace.md),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(MeshRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
      child: Row(
        children: [
          Icon(icon, color: MeshPalette.of(context).textMuted),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

/// Surfaces the Android accessibility-gesture enrollment state (per the
/// Task 8 plan: "surface... gesture-enrollment state clearly") instead of
/// linking out blind to system settings with no indication of whether the
/// service is already enabled.
class _GestureRow extends StatefulWidget {
  const _GestureRow();

  @override
  State<_GestureRow> createState() => _GestureRowState();
}

class _GestureRowState extends State<_GestureRow> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final enabled = await EmergencyGestureSettings.isEnabled();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      // Gesture enrollment is Android-only; the row still opens settings.
    }
  }

  Future<void> _open() async {
    await EmergencyGestureSettings.openSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(MeshRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
        child: Row(
          children: [
            Icon(Icons.settings_accessibility, color: palette.textMuted),
            const SizedBox(width: MeshSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency gestures',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Review Android accessibility access',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_enabled != null) ...[
              MeshStatusPill(
                label: _enabled! ? 'Enabled' : 'Disabled',
                tone: _enabled!
                    ? MeshStatusTone.active
                    : MeshStatusTone.neutral,
              ),
              const SizedBox(width: MeshSpace.sm),
            ],
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
