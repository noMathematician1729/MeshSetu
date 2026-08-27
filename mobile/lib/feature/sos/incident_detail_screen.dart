import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/data/database.dart';
import '../../core/model/model.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../voice/voice_repository.dart';
import 'sos_payload.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({
    super.key,
    required this.siteId,
    required this.eventId,
    required this.objectId,
  });

  final String siteId;
  final String eventId;
  final int objectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return MeshPage(
      title: 'SOS Incident',
      scrollable: false,
      child: StreamBuilder<List<InboxEvent>>(
        stream: db.watchInboxSite(siteId),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <InboxEvent>[];
          InboxEvent? incident;
          for (final row in rows) {
            if (row.eventId == eventId &&
                row.payloadType == PayloadType.structuredSos.name) {
              incident = row;
              break;
            }
          }
          if (incident == null) {
            return const MeshEmptyState(
              icon: Icons.sync_outlined,
              title: 'Syncing',
              message: 'Incident details are still syncing.',
            );
          }
          try {
            final sos = StructuredSosPayload.decode(incident.payload);
            var hasVoice = false;
            for (final row in rows) {
              if (row.payloadType != PayloadType.voiceObject.name) continue;
              try {
                hasVoice |=
                    VoiceObjectPayload.decode(row.payload).sosEventId ==
                    eventId;
              } catch (_) {
                // An unrelated/corrupt voice object does not affect this SOS.
              }
            }
            return ListView(
              children: [
                const MeshStatusPill(
                  label: 'Verified mesh incident',
                  icon: Icons.verified_user_outlined,
                  tone: MeshStatusTone.critical,
                ),
                const SizedBox(height: MeshSpace.md),
                Text(
                  sos.incidentType,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Priority: ${sos.triagePriority.name}'),
                const SizedBox(height: MeshSpace.lg),
                MeshCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MeshDataRow(
                        label: 'Reporter',
                        value: sos.reporter?.name ?? 'Unknown',
                        icon: Icons.person_outline,
                      ),
                      const Divider(height: MeshSpace.sm),
                      MeshDataRow(
                        label: 'Contact',
                        value: sos.reporter == null
                            ? 'Unavailable'
                            : '${sos.reporter!.primaryContactName} · ${sos.reporter!.primaryContactPhone}',
                        icon: Icons.contact_phone_outlined,
                      ),
                      const Divider(height: MeshSpace.sm),
                      if (sos.latitude != null && sos.longitude != null) ...[
                        const SizedBox(height: MeshSpace.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: MeshSpace.xs),
                            Text(
                              'Location',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: MeshSpace.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 180,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  sos.latitude!,
                                  sos.longitude!,
                                ),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'dev.meshsetu.mobile',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        sos.latitude!,
                                        sos.longitude!,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (sos.accuracyM != null)
                          Padding(
                            padding: const EdgeInsets.only(top: MeshSpace.xs),
                            child: Text(
                              '${sos.latitude!.toStringAsFixed(5)}, ${sos.longitude!.toStringAsFixed(5)} · ±${sos.accuracyM!.round()} m',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: MeshSpace.xs),
                            child: Text(
                              '${sos.latitude!.toStringAsFixed(5)}, ${sos.longitude!.toStringAsFixed(5)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: MeshSpace.xs),
                      ] else
                        MeshDataRow(
                          label: 'Location',
                          value: 'Unavailable',
                          icon: Icons.location_on_outlined,
                        ),
                      const Divider(height: MeshSpace.sm),
                      MeshDataRow(
                        label: 'Route',
                        value: '${incident.peerId} · ${incident.receivedAtMs}',
                        icon: Icons.route_outlined,
                      ),
                      const Divider(height: MeshSpace.sm),
                      MeshDataRow(
                        label: 'Voice evidence',
                        value: hasVoice
                            ? 'Received — open Voice evidence to play.'
                            : 'Pending or unavailable.',
                        icon: Icons.graphic_eq_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MeshSpace.md),
                MeshCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MeshMicroLabel('Transcript'),
                      const SizedBox(height: MeshSpace.sm),
                      Text(
                        sos.transcript.isEmpty
                            ? 'Unavailable'
                            : sos.transcript,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } catch (_) {
            return const MeshEmptyState(
              icon: Icons.error_outline,
              title: 'Could not decode incident',
              message: 'The incident payload could not be decoded.',
            );
          }
        },
      ),
    );
  }
}
