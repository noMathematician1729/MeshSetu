import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/data/database.dart';
import '../../core/model/model.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../sos/incident_detail_screen.dart';
import '../sos/sos_payload.dart';
import '../voice/voice_inbox_screen.dart';
import '../voice/voice_repository.dart';

/// Activity tab: everything this device has sent, received, or recorded.
/// Aggregates three existing Drift-backed surfaces that were previously
/// scattered or unreachable — the SOS outbox (`sos_screen.dart`'s delivery
/// states), received incidents (`incident_detail_screen.dart`'s inbox
/// query), and Voice Evidence (`voice_inbox_screen.dart`, previously
/// reachable only via a Rooms shortcut removed in Task 5). No new data
/// layer: every stream here is the same one those screens already read.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(activeSiteProvider);
    return MeshScaffold(
      title: 'Activity',
      subtitle: 'Sent, received, and recorded on this device',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MeshSpace.screen),
            child: site.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: MeshSpace.xxl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => MeshEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load activity',
                message: '$e',
              ),
              data: (manifest) {
                if (manifest == null) {
                  return const MeshEmptyState(
                    icon: Icons.pending_actions_outlined,
                    title: 'Nothing yet',
                    message:
                        'Join an event to see your SOS outbox, received '
                        'incidents, and voice evidence here.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OutboxSection(siteId: manifest.siteId),
                    const SizedBox(height: MeshSpace.xl),
                    _ReceivedIncidentsSection(siteId: manifest.siteId),
                    const SizedBox(height: MeshSpace.xl),
                    _VoiceEvidenceSection(siteId: manifest.siteId),
                    const SizedBox(height: MeshSpace.lg),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Local SOS outbox with delivery state. Same table and state values as
/// `sos_screen.dart`'s `StreamBuilder<OutboxEvent?>` — 'ready' / 'relaying'
/// / 'acked' / 'expired' / 'failed' — surfaced here for every SOS this
/// device has drafted, not just the one most recently composed.
class _OutboxSection extends ConsumerWidget {
  const _OutboxSection({required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<OutboxEvent>>(
      stream:
          (db.select(db.outboxEvents)
                ..where(
                  (t) =>
                      t.siteId.equals(siteId) &
                      t.payloadType.equals(PayloadType.structuredSos.name),
                )
                ..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)]))
              .watch(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <OutboxEvent>[];
        return _ActivitySection(
          title: 'SOS outbox',
          subtitle: rows.isEmpty
              ? null
              : '${rows.length} sent from this device',
          emptyIcon: Icons.outbox_outlined,
          emptyMessage: 'SOS packets you send will appear here.',
          isEmpty: rows.isEmpty,
          children: [for (final row in rows) _OutboxRow(row: row)],
        );
      },
    );
  }
}

class _OutboxRow extends StatelessWidget {
  const _OutboxRow({required this.row});

  final OutboxEvent row;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final (label, tone) = _deliveryStatus(row.state);
    final description = (row.rawText ?? '').trim();
    return MeshCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sos, color: palette.ember),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isEmpty ? 'Emergency SOS' : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                MeshMicroLabel(_formatTime(row.createdAtMs)),
              ],
            ),
          ),
          const SizedBox(width: MeshSpace.sm),
          MeshStatusPill(label: label, tone: tone),
        ],
      ),
    );
  }

  static (String, MeshStatusTone) _deliveryStatus(String? state) =>
      switch (state) {
        'ready' || 'queued' => ('Waiting', MeshStatusTone.neutral),
        'relaying' => ('Relaying', MeshStatusTone.neutral),
        'acked' => ('Delivered', MeshStatusTone.active),
        'expired' => ('Expired', MeshStatusTone.critical),
        'failed' => ('Failed', MeshStatusTone.critical),
        _ => ('Preparing', MeshStatusTone.neutral),
      };
}

/// Received incidents: structured SOS objects relayed to this device over
/// the mesh, same InboxEvents rows `incident_detail_screen.dart` and
/// `sos_incident_screen.dart` read via `db.watchInboxSite`.
class _ReceivedIncidentsSection extends ConsumerWidget {
  const _ReceivedIncidentsSection({required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<InboxEvent>>(
      stream: db.watchInboxSite(siteId),
      builder: (context, snapshot) {
        final rows =
            (snapshot.data ?? const <InboxEvent>[])
                .where(
                  (row) => row.payloadType == PayloadType.structuredSos.name,
                )
                .toList()
              ..sort((a, b) => b.receivedAtMs.compareTo(a.receivedAtMs));
        return _ActivitySection(
          title: 'Received incidents',
          subtitle: rows.isEmpty
              ? null
              : '${rows.length} relayed to this device',
          emptyIcon: Icons.inbox_outlined,
          emptyMessage:
              'SOS incidents relayed to you over the mesh appear here.',
          isEmpty: rows.isEmpty,
          children: [
            for (final row in rows) _IncidentRow(row: row, siteId: siteId),
          ],
        );
      },
    );
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({required this.row, required this.siteId});

  final InboxEvent row;
  final String siteId;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    String title = 'SOS incident';
    String subtitle = row.peerId;
    try {
      final sos = StructuredSosPayload.decode(row.payload);
      title = sos.incidentType.isEmpty ? 'SOS incident' : sos.incidentType;
      subtitle = 'From ${sos.reporter?.name ?? row.peerId}';
    } catch (_) {
      // Undecodable payloads still show as a row using peer/time metadata.
    }
    return MeshCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncidentDetailScreen(
            siteId: siteId,
            eventId: row.eventId,
            objectId: row.objectId,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.ember),
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
    );
  }
}

/// Voice Evidence summary. Previously reachable only from inside Rooms
/// (removed in Task 5); this section shows a count and links into the full
/// `VoiceInboxScreen` for playback, rather than duplicating its list here.
class _VoiceEvidenceSection extends ConsumerWidget {
  const _VoiceEvidenceSection({required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<InboxEvent>>(
      stream:
          (db.select(db.inboxEvents)..where(
                (t) =>
                    t.siteId.equals(siteId) &
                    t.payloadType.equals(PayloadType.voiceObject.name),
              ))
              .watch(),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <InboxEvent>[];
        var verified = 0;
        for (final row in rows) {
          try {
            VoiceObjectPayload.decode(row.payload);
            verified++;
          } catch (_) {
            // Corrupt/unreadable clips are still counted as received but
            // not as verified; VoiceInboxScreen surfaces the distinction.
          }
        }
        return _ActivitySection(
          title: 'Voice evidence',
          subtitle: rows.isEmpty
              ? null
              : '$verified of ${rows.length} verified',
          emptyIcon: Icons.graphic_eq,
          emptyMessage:
              'Verified voice clips received over the mesh appear here.',
          isEmpty: rows.isEmpty,
          children: [
            MeshCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VoiceInboxScreen(siteId: siteId),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.graphic_eq, color: MeshPalette.of(context).mesh),
                  const SizedBox(width: MeshSpace.md),
                  Expanded(
                    child: Text(
                      rows.length == 1
                          ? '1 voice clip received'
                          : '${rows.length} voice clips received',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shared section shell: title, optional subtitle/count, and either the
/// populated rows or an empty state — used by all three Activity sections
/// so they read as one consistent list rather than three different widgets.
class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.subtitle,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.isEmpty,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MeshSectionTitle(title, subtitle: subtitle),
      if (isEmpty)
        MeshCard(
          child: Row(
            children: [
              Icon(emptyIcon, color: MeshPalette.of(context).textMuted),
              const SizedBox(width: MeshSpace.md),
              Expanded(
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )
      else
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: MeshSpace.sm),
        ],
    ],
  );
}

String _formatTime(int milliseconds) {
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
