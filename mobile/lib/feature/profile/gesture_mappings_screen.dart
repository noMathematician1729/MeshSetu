import 'package:flutter/material.dart';

import '../../app/emergency_gestures.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

class GestureMappingsScreen extends StatefulWidget {
  const GestureMappingsScreen({super.key});

  @override
  State<GestureMappingsScreen> createState() => _GestureMappingsScreenState();
}

class _GestureMappingsScreenState extends State<GestureMappingsScreen> {
  Map<EmergencyGesture, String> _mappings = Map.of(
    defaultEmergencyGestureMappings,
  );
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mappings = await EmergencyGestureSettings.loadMappings();
      if (mounted) setState(() => _mappings = mappings);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load saved gestures. Showing defaults.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(EmergencyGesture gesture) async {
    final pattern = await showDialog<String>(
      context: context,
      builder: (_) => _GesturePatternDialog(
        gesture: gesture,
        initialPattern: _mappings[gesture]!,
      ),
    );
    if (pattern == null || !mounted) return;
    final next = Map<EmergencyGesture, String>.of(_mappings)
      ..[gesture] = pattern;
    setState(() {
      _mappings = next;
      _error = validateEmergencyGestureMappings(next);
    });
  }

  Future<void> _save() async {
    final error = validateEmergencyGestureMappings(_mappings);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _saving = true);
    try {
      await EmergencyGestureSettings.saveMappings(_mappings);
      if (mounted) {
        setState(() => _error = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency gestures updated.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save gestures. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _mappings = Map.of(defaultEmergencyGestureMappings);
      _error = null;
    });
    try {
      await EmergencyGestureSettings.resetMappings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default emergency gestures restored.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not restore defaults. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => MeshPage(
    title: 'Emergency gestures',
    child: _loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(MeshSpace.xl),
              child: CircularProgressIndicator(),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MeshStatusPill(
                label: 'Volume buttons · 2–5 presses',
                icon: Icons.volume_up_outlined,
                tone: MeshStatusTone.critical,
              ),
              const SizedBox(height: MeshSpace.md),
              const Text(
                'Choose a unique sequence for each emergency type. Pause briefly after the last press to trigger the SOS confirmation.',
              ),
              const SizedBox(height: MeshSpace.lg),
              MeshCard(
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < EmergencyGesture.values.length;
                      index++
                    ) ...[
                      _MappingRow(
                        gesture: EmergencyGesture.values[index],
                        pattern: _mappings[EmergencyGesture.values[index]]!,
                        onTap: () => _edit(EmergencyGesture.values[index]),
                      ),
                      if (index != EmergencyGesture.values.length - 1)
                        const Divider(height: MeshSpace.sm),
                    ],
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: MeshSpace.md),
                MeshCard(
                  tint: MeshPalette.of(context).ember.withValues(alpha: 0.08),
                  child: Text(_error!),
                ),
              ],
              const SizedBox(height: MeshSpace.lg),
              MeshFullWidthButton(
                label: _saving ? 'Saving gestures…' : 'Save gestures',
                busy: _saving,
                icon: Icons.save_outlined,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: MeshSpace.sm),
              OutlinedButton.icon(
                onPressed: _saving ? null : _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restore default gestures'),
              ),
            ],
          ),
  );
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({
    required this.gesture,
    required this.pattern,
    required this.onTap,
  });

  final EmergencyGesture gesture;
  final String pattern;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(MeshRadius.sm),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshSpace.sm),
      child: Row(
        children: [
          Icon(Icons.sos_outlined, color: MeshPalette.of(context).textMuted),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gesture.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _readablePattern(pattern),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _GesturePatternDialog extends StatefulWidget {
  const _GesturePatternDialog({
    required this.gesture,
    required this.initialPattern,
  });

  final EmergencyGesture gesture;
  final String initialPattern;

  @override
  State<_GesturePatternDialog> createState() => _GesturePatternDialogState();
}

class _GesturePatternDialogState extends State<_GesturePatternDialog> {
  late String _pattern = widget.initialPattern;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.gesture.label} gesture'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _readablePattern(_pattern),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: MeshSpace.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: MeshSpace.sm,
          runSpacing: MeshSpace.sm,
          children: [
            for (final press in _pattern.characters)
              Chip(label: Text(press == 'U' ? 'Up' : 'Down')),
          ],
        ),
        const SizedBox(height: MeshSpace.md),
        Text(
          'Add 2–5 total presses.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: MeshSpace.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pattern.length == 5
                    ? null
                    : () => setState(() => _pattern += 'U'),
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Volume up'),
              ),
            ),
            const SizedBox(width: MeshSpace.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pattern.length == 5
                    ? null
                    : () => setState(() => _pattern += 'D'),
                icon: const Icon(Icons.volume_down_outlined),
                label: const Text('Volume down'),
              ),
            ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _pattern.isEmpty
            ? null
            : () => setState(
                () => _pattern = _pattern.substring(0, _pattern.length - 1),
              ),
        child: const Text('Undo'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _pattern.length >= 2
            ? () => Navigator.of(context).pop(_pattern)
            : null,
        child: const Text('Use sequence'),
      ),
    ],
  );
}

String _readablePattern(String pattern) => pattern.characters
    .map((press) => press == 'U' ? 'Volume up' : 'Volume down')
    .join(' · ');
