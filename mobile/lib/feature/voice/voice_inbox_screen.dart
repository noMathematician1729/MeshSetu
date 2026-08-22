import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../core/data/database.dart';
import '../../core/model/model.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import 'voice_repository.dart';

/// Received voice evidence for a site. `InboxEvents` rows only exist once
/// `MeshRelayEngine` has decrypted and authenticated the reassembled object
/// (see `relay_engine.dart`'s `persist` call), so every row shown here has
/// already passed the envelope integrity check. Voice payload integrity is
/// checked again before playback because the audio has its own digest.
class VoiceInboxScreen extends ConsumerWidget {
  const VoiceInboxScreen({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return MeshPage(
      title: 'Voice Evidence',
      scrollable: false,
      child: StreamBuilder(
        stream:
            (db.select(db.inboxEvents)..where(
                  (t) =>
                      t.siteId.equals(siteId) &
                      t.payloadType.equals(PayloadType.voiceObject.name),
                ))
                .watch(),
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) {
            return const MeshEmptyState(
              icon: Icons.graphic_eq,
              title: 'No voice evidence yet',
              message:
                  'Verified voice clips received over the mesh appear here.',
            );
          }
          return ListView(
            children: [
              for (final row in rows) ...[
                _VoiceRow(row: row),
                const SizedBox(height: MeshSpace.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Plain Row layout instead of ListTile — a ListTile placed directly inside
/// MeshCard's DecoratedBox with no intervening Material ancestor triggers
/// Flutter's "background color or ink splashes may be invisible" assertion
/// under a full theme (same class of bug fixed in Task 8/10).
class _VoiceRow extends StatelessWidget {
  const _VoiceRow({required this.row});

  final InboxEvent row;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    try {
      final voice = VoiceObjectPayload.decode(row.payload);
      return MeshCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: palette.live.withValues(alpha: 0.12),
              foregroundColor: palette.live,
              child: const Icon(Icons.graphic_eq),
            ),
            const SizedBox(width: MeshSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From ${row.peerId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${voice.bytes.length} bytes · integrity verified',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.filled(
              tooltip: 'Play voice evidence',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _play(row.objectId, voice.bytes),
            ),
          ],
        ),
      );
    } on FormatException catch (error) {
      return MeshCard(
        tint: palette.ember.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: palette.ember),
            const SizedBox(width: MeshSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrupt voice evidence from ${row.peerId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    error.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return MeshCard(
        tint: palette.ember.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: palette.ember),
            const SizedBox(width: MeshSpace.md),
            Expanded(
              child: Text(
                'Unreadable voice evidence from ${row.peerId}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _play(int objectId, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/inbox-voice-$objectId.opus');
    await file.writeAsBytes(bytes);
    await AudioPlayer().play(DeviceFileSource(file.path));
  }
}
