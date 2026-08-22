import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/mesh_event_task.dart' show meshEventTaskCallback;
import '../../app/mesh_bridge_client.dart' show MeshStatus;
import '../../app/providers.dart';
import '../../app/room_mesh_bootstrap.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../join/manifest.dart';
import 'room_chat_screen.dart';
import 'room_presence.dart';
import 'room_presence_beacon.dart';
import 'room_presence_socket.dart';

/// Module-level so re-opening the same room lobby within one app session
/// does not re-announce over the mesh every time — announcements persist in
/// the outbox and re-sending is wasted radio time, not a correctness fix.
/// Cleared implicitly on app restart, which is exactly when a fresh
/// announcement is wanted again.
final Set<String> _announcedRoomMembers = {};

/// Presence re-announce cadence while a lobby is open. This is short on
/// purpose: the point is not TTL refresh (presence rows live 24h) but being
/// heard by a peer that connects after this device joined.
const _reannounceInterval = Duration(seconds: 60);

class RoomLobbyScreen extends ConsumerStatefulWidget {
  const RoomLobbyScreen({
    super.key,
    required this.manifest,
    required this.room,
  });

  final EventManifest manifest;
  final RoomManifest room;

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  StreamSubscription<List<RoomMember>>? _meshMembersSubscription;
  RoomPresenceSocket? _presenceSocket;
  List<RoomMember> _meshMembers = const [];
  List<RoomMember> _liveMembers = const [];
  var _receivedLiveSnapshot = false;
  RoomPresenceBeacon? _presenceBeacon;
  var _startingEventMode = false;

  @override
  void initState() {
    super.initState();
    _meshMembersSubscription = ref
        .read(roomRepositoryProvider(widget.manifest.siteId))
        .watchMembers(widget.room.roomId)
        .listen((members) {
          if (mounted) setState(() => _meshMembers = members);
        });
    unawaited(_connectLivePresence());
    // Opening a room is the intent to participate in it. Without the radio up
    // the presence announcement below never leaves the outbox, so nobody in
    // the room can see anybody else offline.
    unawaited(_ensureMeshForRoom());
    _presenceBeacon = RoomPresenceBeacon(
      announce: () => _announcePresence(force: true),
      interval: _reannounceInterval,
      peerCounts: _peerCountStream(),
    )..start();
  }

  /// Peer counts drive an immediate re-announce the moment a phone links up,
  /// which is when a presence packet can finally be delivered.
  Stream<int> _peerCountStream() =>
      ref
          .read(meshBridgeClientProvider)
          ?.meshStatusStream
          .map((status) => status.peerCount) ??
      const Stream<int>.empty();

  /// Starts Event Mode for this room's site if it is not already running.
  /// Idempotent: [RoomMeshBootstrap] reports `alreadyRunning` and simply
  /// re-attaches the outbox bridge in that case.
  Future<void> _ensureMeshForRoom() async {
    final status = ref.read(meshBridgeClientProvider)?.meshStatus;
    if (status?.eventModeRunning == true) return;
    await _startEventModeFromRoom();
  }

  /// Announces this device's membership over the mesh so peers with no
  /// internet still see who is in the room (closes the gap where presence
  /// was only ever announced from the join screen, never from a room a user
  /// opens later). Deduped per room+profile for the life of the app process;
  /// [force] bypasses the dedupe for the periodic re-announce.
  Future<void> _announcePresence({bool force = false}) async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted || profile == null) return;
    final key =
        '${widget.manifest.siteId}\u0000${widget.room.roomId}\u0000'
        '${profile.profileId}';
    if (!force && !_announcedRoomMembers.add(key)) return;
    _announcedRoomMembers.add(key);
    try {
      await ref
          .read(roomRepositoryProvider(widget.manifest.siteId))
          .announceMember(
            roomId: widget.room.roomId,
            memberId: profile.profileId,
            displayName: profile.name,
          );
    } catch (_) {
      // Best-effort; the periodic timer retries, and watchMembers doesn't
      // depend on this device's own announcement to show other peers.
    }
  }

  Future<void> _connectLivePresence() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted || profile == null) return;
    if (!ref.read(gatewayEnabledProvider)) return;
    final rawUrl = ref.read(gatewayUrlProvider).trim();
    if (rawUrl.isEmpty) return;
    final baseUrl = Uri.tryParse(rawUrl);
    if (baseUrl == null || !baseUrl.hasScheme) return;
    final presence = RoomPresenceSocket(
      baseUrl: baseUrl,
      gatewayKey: ref.read(gatewayDemoKeyProvider),
      siteId: widget.manifest.siteId,
      roomId: widget.room.roomId,
      memberId: profile.profileId,
      displayName: profile.name,
    );
    _presenceSocket = presence;
    presence.members.listen((members) {
      if (!mounted) return;
      setState(() {
        _receivedLiveSnapshot = true;
        _liveMembers = members;
      });
    });
    presence.start();
  }

  Future<void> _startEventModeFromRoom() async {
    if (_startingEventMode) return;
    setState(() => _startingEventMode = true);
    try {
      await RoomMeshBootstrap.startForSite(
        ref: ref,
        siteId: widget.manifest.siteId,
        taskCallback: meshEventTaskCallback,
      );
    } finally {
      if (mounted) setState(() => _startingEventMode = false);
    }
  }

  @override
  void dispose() {
    unawaited(_meshMembersSubscription?.cancel());
    unawaited(_presenceSocket?.dispose());
    unawaited(_presenceBeacon?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meshStatus = ref.watch(meshStatusProvider);
    // A live socket snapshot is additive evidence, not a replacement: a
    // member who only ever appears over the mesh (no internet) must still
    // show up even after the socket connects.
    final members = <String, RoomMember>{
      for (final member in _meshMembers) member.memberId: member,
      if (_receivedLiveSnapshot)
        for (final member in _liveMembers) member.memberId: member,
    }.values.toList()..sort((a, b) => a.joinedAtMs.compareTo(b.joinedAtMs));
    final manifest = widget.manifest;
    final room = widget.room;
    final invite = EventManifestCodec.encode(manifest, roomId: room.roomId);
    return MeshPage(
      title: room.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeshMicroLabel(manifest.siteName),
          const SizedBox(height: MeshSpace.md),
          meshStatus.when(
            data: (status) => _MeshStatusBanner(
              status: status,
              starting: _startingEventMode,
              onStartEventMode: _startEventModeFromRoom,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: MeshSpace.lg),
          MeshCard(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox.square(
                  dimension: constraints.maxWidth < 260
                      ? constraints.maxWidth
                      : 260,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(MeshSpace.md),
                    child: QrImageView(
                      data: invite,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          _CodeTile(label: 'Room code', value: room.roomId),
          const SizedBox(height: MeshSpace.sm),
          _CodeTile(label: 'Event code', value: manifest.meshCode),
          const SizedBox(height: MeshSpace.lg),
          MeshFullWidthButton(
            icon: Icons.forum_outlined,
            label: 'Open room chat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RoomChatScreen(
                  siteId: manifest.siteId,
                  roomId: room.roomId,
                  roomName: room.name,
                  role: room.role,
                ),
              ),
            ),
          ),
          const SizedBox(height: MeshSpace.xl),
          MeshSectionTitle(
            'People in this room',
            subtitle: members.isEmpty
                ? null
                : '${members.length} member${members.length == 1 ? '' : 's'}',
          ),
          // Connected to phones but still alone in the room almost always
          // means the other device is in a different room: membership and
          // messages are both filtered by exact room code. Say so, and show
          // the code to compare, instead of leaving an empty list.
          if (meshStatus.valueOrNull case final status?)
            if (status.peerCount > 0 && members.length <= 1)
              Padding(
                padding: const EdgeInsets.only(bottom: MeshSpace.sm),
                child: MeshStatusPill(
                  label:
                      '${status.peerCount} device'
                      '${status.peerCount == 1 ? '' : 's'} linked · compare the '
                      'room code below if nobody appears',
                  icon: Icons.info_outline,
                  tone: MeshStatusTone.neutral,
                ),
              ),
          members.isEmpty
              ? const MeshEmptyState(
                  icon: Icons.person_outline,
                  title: 'Waiting for people to join',
                  message:
                      'Members appear here over the mesh or once they '
                      'scan the QR.',
                )
              : Column(
                  children: [
                    for (final member in members) ...[
                      MeshCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              foregroundColor: MeshPalette.of(context).text,
                              child: Text(
                                member.displayName.characters.first
                                    .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: MeshSpace.md),
                            Expanded(
                              child: Text(
                                member.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            MeshStatusPill(
                              label:
                                  _liveMembers.any(
                                    (m) => m.memberId == member.memberId,
                                  )
                                  ? 'Active now'
                                  : 'Seen over mesh',
                              tone:
                                  _liveMembers.any(
                                    (m) => m.memberId == member.memberId,
                                  )
                                  ? MeshStatusTone.active
                                  : MeshStatusTone.neutral,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: MeshSpace.sm),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}

/// Mesh-first connectivity summary. This is deliberately the primary status
/// surface for the lobby — the internet socket status shown inside
/// [RoomChatScreen] is secondary/muted, since a healthy offline BLE mesh
/// with zero internet must not look like a broken room.
class _MeshStatusBanner extends StatelessWidget {
  const _MeshStatusBanner({
    required this.status,
    required this.starting,
    required this.onStartEventMode,
  });

  final MeshStatus status;
  final bool starting;
  final VoidCallback onStartEventMode;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    if (!status.eventModeRunning) {
      final blockedReason = status.blockedReason;
      return MeshCard(
        child: Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: palette.textMuted),
            const SizedBox(width: MeshSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blockedReason != null
                        ? 'Event mode is blocked'
                        : 'Event mode is off',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    blockedReason ??
                        'Messages will queue until you start the BLE relay service.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: MeshSpace.sm),
            FilledButton(
              onPressed: starting ? null : onStartEventMode,
              child: starting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start'),
            ),
          ],
        ),
      );
    }
    final peerCount = status.peerCount;
    return MeshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                peerCount > 0
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
                color: peerCount > 0 ? palette.live : palette.mesh,
              ),
              const SizedBox(width: MeshSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peerCount > 0
                          ? 'Mesh: $peerCount peer${peerCount == 1 ? '' : 's'} connected'
                          : 'Mesh: no peers yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      peerCount > 0
                          ? 'Messages relay over Bluetooth.'
                          : 'Move closer to another device with event mode on.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.siteMismatchDetected) ...[
            const SizedBox(height: MeshSpace.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 18, color: palette.caution),
                const SizedBox(width: MeshSpace.sm),
                Expanded(
                  child: Text(
                    'A nearby device is using a different event/site code. '
                    'It will not appear here or connect until it joins '
                    'this event.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MeshCard(
    child: Row(
      children: [
        Icon(Icons.key_outlined, color: MeshPalette.of(context).textMuted),
        const SizedBox(width: MeshSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeshMicroLabel(label),
              SelectableText(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
