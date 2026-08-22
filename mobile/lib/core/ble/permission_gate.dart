import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import 'ble_permissions.dart';

/// Blocks the app until the runtime permissions required by the BLE mesh have
/// been granted. This follows CEAL's onboarding model: users can retry or go
/// to Android settings, but cannot enter the event UI with a half-authorized
/// radio.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  List<Permission> _required = const [];
  Map<Permission, PermissionStatus> _statuses = const {};
  bool _loading = true;
  bool _requesting = false;
  bool _bluetoothEnabled = true;

  bool get _allGranted {
    if (_loading) return false;
    if (_required.isEmpty) return true;
    return _statuses.length == _required.length &&
        _statuses.values.every((status) => status.isGranted) &&
        _bluetoothEnabled;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_allGranted) {
      unawaited(_refresh());
    }
  }

  Future<void> _load() async {
    // The deployed app is Android-only. Keep widget tests and non-Android
    // tooling usable without trying to invoke Android platform channels.
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    _required = BlePermissions.runtimePermissions(
      sdkInt: androidInfo.version.sdkInt,
    );
    await _refresh();
    if (mounted && !_allGranted) {
      // Request on first launch as well as from the visible button. If Android
      // has permanently denied one, the screen remains here with Settings.
      await _requestPermissions();
    }
  }

  Future<void> _refresh() async {
    if (_required.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final statuses = <Permission, PermissionStatus>{
      for (final permission in _required) permission: await permission.status,
    };
    var bluetoothEnabled = true;
    if (_required.contains(Permission.bluetoothScan)) {
      bluetoothEnabled =
          await Permission.bluetooth.serviceStatus == ServiceStatus.enabled;
    }
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _bluetoothEnabled = bluetoothEnabled;
      _loading = false;
    });
  }

  Future<void> _requestPermissions() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      // Ask one permission at a time so the location dialog is not hidden by
      // Android's Bluetooth permission group handling.
      for (final permission in _required) {
        if (!(await permission.status).isGranted) {
          await permission.request();
        }
      }
      await _refresh();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  String _label(Permission permission) {
    if (permission == Permission.bluetoothScan) return 'Bluetooth scan';
    if (permission == Permission.bluetoothAdvertise) {
      return 'Bluetooth advertise';
    }
    if (permission == Permission.bluetoothConnect) {
      return 'Bluetooth connection';
    }
    if (permission == Permission.locationWhenInUse) return 'Location';
    if (permission == Permission.notification) return 'Notifications';
    return permission.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_allGranted) return widget.child;
    final palette = MeshPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions required')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 64,
                          color: palette.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'MeshSetu needs permission before you can enter the app.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bluetooth and location are required to discover, send, '
                          'and receive mesh messages. Notifications keep the relay '
                          'alive while the app is in the background.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          MeshCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final permission in _required) ...[
                                  _PermissionRow(
                                    label: _label(permission),
                                    granted:
                                        _statuses[permission]?.isGranted ==
                                        true,
                                  ),
                                  if (permission != _required.last)
                                    const Divider(height: MeshSpace.sm),
                                ],
                                if (!_bluetoothEnabled) ...[
                                  const Divider(height: MeshSpace.sm),
                                  _PermissionRow(
                                    label: 'Turn Bluetooth on to continue',
                                    granted: false,
                                    icon: Icons.bluetooth_disabled,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _requesting ? null : _requestPermissions,
                            icon: _requesting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.shield_outlined),
                            label: Text(
                              _requesting ? 'Requesting…' : 'Grant permissions',
                            ),
                          ),
                          if (_statuses.values.any(
                            (status) => status.isPermanentlyDenied,
                          ))
                            TextButton(
                              onPressed: openAppSettings,
                              child: const Text('Open Android settings'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Plain Row layout instead of ListTile — a ListTile placed directly inside
/// MeshCard's DecoratedBox with no intervening Material ancestor triggers
/// Flutter's "background color or ink splashes may be invisible" assertion
/// under a full theme (same class of bug fixed in Task 8 for
/// settings_screen.dart/gateway_screen.dart).
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.granted,
    this.icon,
  });

  final String label;
  final bool granted;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
      child: Row(
        children: [
          Icon(
            icon ?? (granted ? Icons.check_circle : Icons.cancel_outlined),
            color: granted ? palette.live : palette.ember,
          ),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
