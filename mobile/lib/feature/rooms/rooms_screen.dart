import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../join/manifest.dart';
import 'room_lobby_screen.dart';
import 'room_policy.dart';

/// Derives a room ID that is identical on every phone that creates the same
/// room name.
///
/// This used to append `DateTime.now()`, which guaranteed divergence: two
/// people creating "Medical Bay" in the same event got different room IDs and
/// could never see each other's presence or messages, because both are
/// filtered by exact room ID. A stable digest keeps IDs collision-resistant
/// while making the same name mean the same room, so a typed mesh code is
/// enough to meet in a room without scanning a QR.
String _roomIdFromName(String name) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final normalized = slug.isEmpty ? 'room' : slug;
  final digest = sha256.convert(utf8.encode('meshsetu-room-v1:$normalized'));
  final suffix = digest.bytes
      .take(2)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '$normalized-$suffix';
}

/// Room list for the joined site (Bible §20.5: "Join -> Rooms -> SOS flow
/// is understandable in under 30 seconds"). As of Task 3, Send SOS, Voice
/// Evidence, and Gateway have their own tabs/named routes, so this screen
/// is scoped to room-list content only rather than acting as a general
/// navigation hub.
class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key, this.initialRoomId});

  final String? initialRoomId;

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  var _openedInitialRoom = false;

  @override
  Widget build(BuildContext context) {
    final site = ref.watch(activeSiteProvider);
    final userRoles = ref.watch(userRolesProvider);
    return MeshScaffold(
      title: 'Rooms',
      subtitle: 'Coordinate securely with people nearby',
      actions: [
        IconButton(
          tooltip: 'Create another room',
          onPressed: () => _createRoom(context, ref),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
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
                title: 'Could not load your site',
                message: '$e',
              ),
              data: (manifest) {
                if (manifest == null) {
                  return const MeshEmptyState(
                    icon: Icons.explore_outlined,
                    title: 'Join an event first',
                    message:
                        'Scan a QR code or enter a mesh code from the '
                        'onboarding flow to see rooms here.',
                  );
                }
                final readableRooms = manifest.rooms
                    .where(
                      (room) => canRead(
                        policyForRole(room.roomId, room.role),
                        userRoles,
                      ),
                    )
                    .toList();
                final initialRoomId = widget.initialRoomId;
                final matchingRooms = initialRoomId == null
                    ? const <RoomManifest>[]
                    : readableRooms
                          .where((room) => room.roomId == initialRoomId)
                          .toList();
                final initialRoom = matchingRooms.isEmpty
                    ? null
                    : matchingRooms.first;
                if (!_openedInitialRoom && initialRoom != null) {
                  _openedInitialRoom = true;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _openLobby(context, manifest, initialRoom),
                  );
                }
                if (readableRooms.isEmpty) {
                  return MeshEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No rooms yet',
                    message:
                        'Create the first room so people nearby can '
                        'coordinate securely.',
                    action: FilledButton.icon(
                      onPressed: () => _createRoom(context, ref),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create a room'),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final room in readableRooms) ...[
                      MeshCard(
                        onTap: () => _openLobby(context, manifest, room),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: MeshPalette.of(
                                  context,
                                ).primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.forum_outlined,
                                color: MeshPalette.of(context).primary,
                              ),
                            ),
                            const SizedBox(width: MeshSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    room.role,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Open room lobby',
                              icon: const Icon(Icons.meeting_room_outlined),
                              onPressed: () =>
                                  _openLobby(context, manifest, room),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MeshSpace.sm),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    final room = await showModalBottomSheet<RoomManifest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateRoomSheet(),
    );
    if (room == null || !context.mounted) return;
    try {
      final updated = await ref
          .read(joinRepositoryProvider)
          .addRoomToActiveManifest(room);
      refreshActiveSite(ref);
      if (!context.mounted) return;
      _openLobby(context, updated, room);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create room: $error')));
    }
  }

  void _openLobby(
    BuildContext context,
    EventManifest manifest,
    RoomManifest room,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomLobbyScreen(manifest: manifest, room: room),
      ),
    );
  }
}

class _CreateRoomSheet extends StatefulWidget {
  const _CreateRoomSheet();

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final _nameController = TextEditingController();
  var _role = 'public';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      RoomManifest(
        roomId: _roomIdFromName(name),
        name: name,
        role: _role,
        ttlSeconds: 3600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        MeshSpace.screen,
        MeshSpace.sm,
        MeshSpace.screen,
        MediaQuery.viewInsetsOf(context).bottom + MeshSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create room', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: MeshSpace.md),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Room name',
              hintText: 'e.g. Registration Desk',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: MeshSpace.md),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Room access'),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'volunteer', child: Text('Volunteer')),
              DropdownMenuItem(value: 'medical', child: Text('Medical')),
              DropdownMenuItem(value: 'responder', child: Text('Responder')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: MeshSpace.lg),
          MeshFullWidthButton(label: 'Create', onPressed: _submit),
        ],
      ),
    ),
  );
}
