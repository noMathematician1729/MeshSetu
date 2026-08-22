import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import 'location_capture.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _region = TextEditingController();
  LocationCaptureResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _address.dispose();
    _area.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    setState(() => _loading = true);
    final permission = await Permission.locationWhenInUse.request();
    final result = permission.isGranted
        ? await const LocationCapture().capture()
        : const LocationCaptureResult.failure(
            LocationFailureReason.permissionDenied,
          );
    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _result?.location;
    final palette = MeshPalette.of(context);
    return MeshPage(
      title: 'Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(MeshRadius.lg),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                Icon(Icons.location_pin, color: palette.primary, size: 48),
                Positioned(
                  bottom: MeshSpace.sm,
                  child: MeshStatusPill(
                    label: location == null
                        ? 'Location not captured'
                        : location.accuracyM == null
                        ? 'Location captured'
                        : '±${location.accuracyM!.round()} m accuracy',
                    tone: location == null
                        ? MeshStatusTone.neutral
                        : MeshStatusTone.active,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          MeshFullWidthButton(
            label: location == null
                ? 'Use current location'
                : 'Refresh location',
            icon: Icons.my_location,
            busy: _loading,
            onPressed: _capture,
          ),
          if (_result != null) ...[
            const SizedBox(height: MeshSpace.sm),
            Text(
              location == null
                  ? _result!.status
                  : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: MeshSpace.lg),
          const MeshSectionTitle(
            'Manual address',
            subtitle: 'Add an address when GPS is unavailable or imprecise.',
          ),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'House / street address',
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _area,
                  decoration: const InputDecoration(
                    labelText: 'Village / area',
                  ),
                ),
              ),
              const SizedBox(width: MeshSpace.sm),
              Expanded(
                child: TextField(
                  controller: _region,
                  decoration: const InputDecoration(
                    labelText: 'District / state',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 20.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x + 50, size.height), paint);
    }
    for (var y = 20.0; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter oldDelegate) => oldDelegate.color != color;
}
