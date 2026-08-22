import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../gateway/gateway_bridge.dart';

/// Native recipient-facing view of a single SOS.
///
/// The API payload is the same incident record shown in the admin dashboard;
/// the app deliberately omits operator-only actions such as acknowledgement
/// and dispatch state changes.
class SosIncidentScreen extends ConsumerStatefulWidget {
  const SosIncidentScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<SosIncidentScreen> createState() => _SosIncidentScreenState();
}

class _SosIncidentScreenState extends ConsumerState<SosIncidentScreen> {
  Map<String, Object?>? _incident;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final url = ref.read(gatewayUrlProvider);
    final key = ref.read(gatewayDemoKeyProvider);
    final incident = url.isEmpty
        ? null
        : await GatewayBridge(
            baseUrl: Uri.parse(url),
            demoKey: key,
          ).fetchPublicIncident(widget.eventId);
    if (!mounted) return;
    setState(() {
      _incident = incident;
      _loading = false;
      _error = incident == null
          ? 'This SOS is unavailable or its details have not reached the server yet.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final incident = _incident;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _UnavailableState(error: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(MeshSpace.screen),
                children: [
                  _IncidentHeader(incident: incident!),
                  const SizedBox(height: MeshSpace.md),
                  _Transcript(transcript: _text(incident['transcript'])),
                  const SizedBox(height: MeshSpace.lg),
                  const MeshSectionTitle('Incident details'),
                  _FactsCard(incident: incident),
                  const SizedBox(height: MeshSpace.md),
                  const MeshCard(
                    child: Text(
                      'This is the live SOS detail shared with you. '
                      'Pull down to refresh updates from the response team.',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.error, required this.onRetry});

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => MeshEmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'Details unavailable',
    message: error,
    action: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Retry'),
    ),
  );
}

class _IncidentHeader extends StatelessWidget {
  const _IncidentHeader({required this.incident});

  final Map<String, Object?> incident;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final status = _text(incident['status']).isEmpty
        ? 'new'
        : _text(incident['status']);
    final priority = _text(incident['priority']);
    final resolved = status == 'resolved';
    return MeshCard(
      tint: resolved ? null : palette.ember.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                resolved ? Icons.check_circle : Icons.warning,
                color: resolved ? palette.live : palette.ember,
              ),
              const SizedBox(width: MeshSpace.sm),
              Expanded(
                child: Text(
                  _display(_text(incident['incident_type'])),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: MeshSpace.md),
          Wrap(
            spacing: MeshSpace.sm,
            runSpacing: MeshSpace.sm,
            children: [
              MeshStatusPill(
                label: 'Status: ${_display(status)}',
                tone: resolved
                    ? MeshStatusTone.active
                    : MeshStatusTone.critical,
              ),
              if (priority.isNotEmpty)
                MeshStatusPill(label: 'Priority: ${_display(priority)}'),
              if (_text(incident['zone']).isNotEmpty)
                MeshStatusPill(label: 'Zone: ${_text(incident['zone'])}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript({required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) => MeshCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MeshMicroLabel('Signal transcript'),
        const SizedBox(height: MeshSpace.sm),
        Text(
          transcript.isEmpty
              ? 'No transcript was attached to this SOS.'
              : transcript,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

/// Telemetry facts rendered through [MeshDataRow] so every numeric/ID field
/// (relay hops, latency, confidence, packet hash) shares one tabular-figure
/// treatment instead of the ad hoc grid the pre-revamp screen used.
class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.incident});

  final Map<String, Object?> incident;

  @override
  Widget build(BuildContext context) {
    final latitude = _number(incident['latitude']);
    final longitude = _number(incident['longitude']);
    final location = latitude == null || longitude == null
        ? 'Unavailable'
        : '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'
              '${_number(incident['accuracy_m']) == null ? '' : ' · ±${_number(incident['accuracy_m'])!.round()} m'}';
    final facts = <(String, String, IconData)>[
      (
        'Reporter',
        _combine(
          _text(incident['reporter_name']),
          _text(incident['reporter_phone']),
        ),
        Icons.person_outline,
      ),
      (
        'Emergency contact',
        _value(incident['reporter_primary_contact']),
        Icons.contact_phone_outlined,
      ),
      (
        'Blood group',
        _value(incident['reporter_blood_group']),
        Icons.bloodtype_outlined,
      ),
      ('Location', location, Icons.location_on_outlined),
      (
        'Received',
        _formatTime(incident['received_at_ms'] ?? incident['created_at_ms']),
        Icons.schedule_outlined,
      ),
      ('Relay hops', _value(incident['hops']), Icons.route_outlined),
      (
        'Origin latency',
        _milliseconds(incident['relay_latency_ms']),
        Icons.speed_outlined,
      ),
      (
        'Voice evidence',
        _value(incident['audio_state']),
        Icons.graphic_eq_outlined,
      ),
      (
        'Triage confidence',
        _confidence(incident['triage_confidence']),
        Icons.insights_outlined,
      ),
      (
        'Verification',
        _value(incident['decrypt_status']),
        Icons.verified_user_outlined,
      ),
      ('Incident ID', _value(incident['event_id']), Icons.tag_outlined),
      (
        'Packet hash',
        _shortHash(_text(incident['packet_sha256'])),
        Icons.fingerprint_outlined,
      ),
    ];
    return MeshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            MeshDataRow(
              label: facts[i].$1,
              value: facts[i].$2,
              icon: facts[i].$3,
            ),
            if (i != facts.length - 1) const Divider(height: MeshSpace.sm),
          ],
        ],
      ),
    );
  }
}

String _text(Object? value) {
  final text = '${value ?? ''}'.trim();
  return text == 'null' ? '' : text;
}

String _value(Object? value) {
  final text = _text(value);
  return text.isEmpty ? 'Unavailable' : text;
}

String _combine(String left, String right) {
  if (left.isEmpty && right.isEmpty) return 'Unavailable';
  return [left, right].where((value) => value.isNotEmpty).join(' · ');
}

double? _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

String _milliseconds(Object? value) {
  final number = _number(value);
  return number == null ? 'Unavailable' : '${number.round()} ms';
}

String _confidence(Object? value) {
  final number = _number(value);
  return number == null ? 'Unavailable' : '${(number * 100).round()}%';
}

String _shortHash(String value) => value.isEmpty
    ? 'Unavailable'
    : value.length <= 12
    ? value
    : value.substring(0, 12);

String _display(String value) => value.replaceAll('_', ' ');

String _formatTime(Object? value) {
  final milliseconds = value is num
      ? value.toInt()
      : int.tryParse('${value ?? ''}');
  if (milliseconds == null) return 'Unavailable';
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
