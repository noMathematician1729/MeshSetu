import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/active_room_reporter.dart';
import '../../app/mesh_event_task.dart' show meshEventTaskCallback;
import '../../app/mesh_bridge_client.dart' show MeshStatus;
import '../../app/providers.dart';
import '../../app/room_mesh_bootstrap.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../location/location_capture.dart';
import 'room_message_dispatcher.dart';
import 'room_lobby_screen.dart';
import 'room_policy.dart';
import 'room_presence_socket.dart';
import 'room_repository.dart';

class RoomChatScreen extends ConsumerStatefulWidget {
  const RoomChatScreen({
    super.key,
    required this.siteId,
    required this.roomId,
    required this.roomName,
    required this.role,
  });

  final String siteId, roomId, roomName, role;

  @override
  ConsumerState<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends ConsumerState<RoomChatScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  RoomPresenceSocket? _liveTransport;
  String _liveStatus = 'Connecting…';
  String? _error;
  var _startingEventMode = false;
  late final ActiveRoomReporter _activeRoomReporter;

  @override
  void initState() {
    super.initState();
    _activeRoomReporter = ActiveRoomReporter(roomId: widget.roomId);
    WidgetsBinding.instance.addObserver(this);
    // Report this room as active immediately — any notifications for it
    // that arrive while the screen is mounted and foregrounded are suppressed.
    _activeRoomReporter.reportActive();
    unawaited(_connectLiveTransport());
    unawaited(_announcePresence());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App returned to foreground with this screen still on top.
        _activeRoomReporter.reportActive();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // App moved to background — notifications should fire.
        _activeRoomReporter.reportInactive();
    }
  }

  /// Closes the same presence gap as [RoomLobbyScreen]: entering chat
  /// directly (e.g. from a deep link) should still put this device on
  /// peers' member lists without requiring a lobby visit first.
  Future<void> _announcePresence() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted || profile == null) return;
    try {
      await ref
          .read(roomRepositoryProvider(widget.siteId))
          .announceMember(
            roomId: widget.roomId,
            memberId: profile.profileId,
            displayName: profile.name,
          );
    } catch (_) {
      // Best-effort; the lobby's periodic re-announce also covers this room.
    }
  }

  Future<void> _connectLiveTransport() async {
    if (!ref.read(gatewayEnabledProvider)) {
      if (mounted) setState(() => _liveStatus = 'disabled');
      return;
    }
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted || profile == null) return;
    final rawUrl = ref.read(gatewayUrlProvider).trim();
    final baseUrl = Uri.tryParse(rawUrl);
    if (baseUrl == null || !baseUrl.hasScheme) {
      if (mounted) setState(() => _liveStatus = 'not configured');
      return;
    }
    final socket = RoomPresenceSocket(
      baseUrl: baseUrl,
      gatewayKey: ref.read(gatewayDemoKeyProvider),
      siteId: widget.siteId,
      roomId: widget.roomId,
      memberId: profile.profileId,
      displayName: profile.name,
    );
    _liveTransport = socket;
    socket.debug.listen((status) {
      if (mounted) setState(() => _liveStatus = status);
    });
    socket.messages.listen((message) {
      if (!mounted || message.memberId == profile.profileId) return;
      // A message the socket delivers from someone else is durably stored
      // so it renders alongside mesh-delivered messages from `watch()` and
      // survives navigating away and back.
      unawaited(
        ref
            .read(roomRepositoryProvider(widget.siteId))
            .storeSocketMessage(
              roomId: widget.roomId,
              eventId: message.messageId,
              text: message.text,
              fromPeerId: message.displayName,
              sentAtMs: message.sentAtMs,
            ),
      );
    });
    socket.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Room is no longer visible — re-enable notifications for it.
    _activeRoomReporter.reportInactive();
    _textController.dispose();
    unawaited(_liveTransport?.dispose());
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final policy = policyForRole(widget.roomId, widget.role);
    final userRoles = ref.read(userRolesProvider);
    try {
      await RoomMessageDispatcher(
        ref.read(roomRepositoryProvider(widget.siteId)),
        _liveTransport,
      ).send(policy: policy, userRoles: userRoles, text: text);
      _textController.clear();
      setState(() => _error = null);
    } on StateError catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _sendStructured(String type, String content) async {
    _textController.text = '[[$type]]$content';
    await _send();
  }

  Future<void> _shareLocation() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      setState(
        () => _error = 'Location permission is needed to share your position.',
      );
      return;
    }
    final result = await const LocationCapture().capture();
    final location = result.location;
    if (location == null) {
      setState(() => _error = result.status);
      return;
    }
    await _sendStructured(
      'location',
      '${location.latitude.toStringAsFixed(5)},${location.longitude.toStringAsFixed(5)},${location.accuracyM?.round() ?? 'unknown'}',
    );
  }

  Future<void> _shareProfile() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (profile == null) {
      setState(() => _error = 'Complete your profile before sharing it.');
      return;
    }
    await _sendStructured('profile', '${profile.name}|${profile.phone}');
  }

  Future<void> _shareMedical() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (profile == null) {
      setState(
        () => _error = 'Complete your medical profile before sharing it.',
      );
      return;
    }
    final medical = profile.medicalProfile;
    await _sendStructured(
      'medical',
      '${medical.bloodGroup}|${medical.allergies}|${medical.conditions}',
    );
  }

  Future<void> _startEventModeFromRoom() async {
    if (_startingEventMode) return;
    setState(() => _startingEventMode = true);
    try {
      await RoomMeshBootstrap.startForSite(
        ref: ref,
        siteId: widget.siteId,
        taskCallback: meshEventTaskCallback,
      );
    } finally {
      if (mounted) setState(() => _startingEventMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final userRoles = ref.watch(userRolesProvider);
    final policy = policyForRole(widget.roomId, widget.role);
    if (!canRead(policy, userRoles)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.roomName)),
        body: const Center(
          child: Text('You are not authorized to view this room.'),
        ),
      );
    }
    final messages = ref.watch(
      roomMessagesProvider((
        siteId: widget.siteId,
        roomId: widget.roomId,
        role: widget.role,
        userRoles: userRoles,
      )),
    );
    final meshStatus = ref.watch(meshStatusProvider);
    final manifest = ref.watch(activeSiteProvider).valueOrNull;
    final matchingRoom = manifest?.rooms
        .where((room) => room.roomId == widget.roomId)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            Text(
              'Emergency room · ${widget.role}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (manifest != null &&
              matchingRoom != null &&
              matchingRoom.isNotEmpty)
            IconButton(
              tooltip: 'Share room invite',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RoomLobbyScreen(
                    manifest: manifest,
                    room: matchingRoom.first,
                  ),
                ),
              ),
              icon: const Icon(Icons.ios_share_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          meshStatus.when(
            data: (status) => _MeshStatusBar(
              status: status,
              starting: _startingEventMode,
              onStartEventMode: _startEventModeFromRoom,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              MeshSpace.md,
              MeshSpace.sm,
              MeshSpace.md,
              MeshSpace.xs,
            ),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  onTap: _shareLocation,
                ),
                _QuickAction(
                  icon: Icons.person_outline,
                  label: 'Profile',
                  onTap: _shareProfile,
                ),
                _QuickAction(
                  icon: Icons.medical_information_outlined,
                  label: 'Medical',
                  onTap: _shareMedical,
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                final visible = items.toList()
                  ..sort((a, b) => a.atMs.compareTo(b.atMs));
                if (visible.isEmpty) {
                  return const MeshEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No messages yet',
                    message: 'Send the first message to this room.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: MeshSpace.sm),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final m = visible[visible.length - 1 - i];
                    final status = meshStatus.valueOrNull;
                    final reason = m.mine
                        ? queuedReasonFor(
                            m,
                            eventModeRunning: status?.eventModeRunning ?? false,
                            peerCount: status?.peerCount ?? 0,
                            blockedReason: status?.blockedReason,
                            siteMismatchDetected:
                                status?.siteMismatchDetected ?? false,
                            nowMs: DateTime.now().millisecondsSinceEpoch,
                          )
                        : null;
                    return _MessageBubble(
                      text: m.text,
                      mine: m.mine,
                      sender: m.mine ? 'You' : (m.fromPeerId ?? 'Peer'),
                      reason: reason,
                      deliveryState: m.mine ? m.state : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cloud: $_liveStatus',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.ember),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MeshSpace.sm,
              MeshSpace.xs,
              MeshSpace.sm,
              MeshSpace.sm,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLength: policy.maxMessageBytes,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: MeshSpace.sm),
                  IconButton.filled(
                    tooltip: 'Send message',
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: MeshSpace.sm),
    child: ActionChip(
      avatar: Icon(icon, size: 18, color: MeshPalette.of(context).primary),
      label: Text(label),
      onPressed: onTap,
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.mine,
    required this.sender,
    required this.reason,
    required this.deliveryState,
  });

  final String text;
  final bool mine;
  final String sender;
  final String? reason;
  final RoomMessageState? deliveryState;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final structured = _StructuredMessage.tryParse(text);
    final foreground = mine
        ? palette.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.symmetric(
          horizontal: MeshSpace.md,
          vertical: MeshSpace.xs,
        ),
        padding: const EdgeInsets.all(MeshSpace.md),
        decoration: BoxDecoration(
          color: mine
              ? palette.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(MeshRadius.md),
            topRight: const Radius.circular(MeshRadius.md),
            bottomLeft: Radius.circular(mine ? MeshRadius.md : MeshSpace.xs),
            bottomRight: Radius.circular(mine ? MeshSpace.xs : MeshRadius.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (structured == null)
              Text(text, style: TextStyle(color: foreground))
            else
              _StructuredMessageCard(
                message: structured,
                foreground: foreground,
              ),
            const SizedBox(height: MeshSpace.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    reason ?? sender,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: .72),
                    ),
                  ),
                ),
                if (deliveryState != null) ...[
                  const SizedBox(width: MeshSpace.sm),
                  _DeliveryStateIcon(state: deliveryState!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StructuredMessage {
  const _StructuredMessage(this.type, this.values);

  final String type;
  final List<String> values;

  static _StructuredMessage? tryParse(String value) {
    final match = RegExp(
      r'^\[\[(location|profile|medical)\]\](.*)$',
    ).firstMatch(value);
    if (match == null) return null;
    final type = match.group(1)!;
    final separator = type == 'location' ? ',' : '|';
    return _StructuredMessage(type, match.group(2)!.split(separator));
  }
}

class _StructuredMessageCard extends StatelessWidget {
  const _StructuredMessageCard({
    required this.message,
    required this.foreground,
  });

  final _StructuredMessage message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final (icon, title, lines) = switch (message.type) {
      'location' => (
        Icons.location_on_outlined,
        'Shared location',
        [
          if (message.values.length >= 2)
            '${message.values[0]}, ${message.values[1]}',
          if (message.values.length >= 3) 'Accuracy ±${message.values[2]} m',
        ],
      ),
      'profile' => (
        Icons.person_outline,
        'Profile information',
        message.values,
      ),
      _ => (
        Icons.medical_information_outlined,
        'Medical information',
        [
          if (message.values.isNotEmpty)
            'Blood type: ${_value(message.values[0])}',
          if (message.values.length >= 2)
            'Allergies: ${_value(message.values[1])}',
          if (message.values.length >= 3)
            'Conditions: ${_value(message.values[2])}',
        ],
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: MeshSpace.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
        const SizedBox(height: MeshSpace.sm),
        for (final line in lines)
          Text(line, style: TextStyle(color: foreground)),
      ],
    );
  }

  static String _value(String value) =>
      value.trim().isEmpty ? 'Not provided' : value.trim();
}

/// Mesh-first status strip shown above the message list, primary over the
/// muted internet-socket line at the bottom of the screen.
class _MeshStatusBar extends StatelessWidget {
  const _MeshStatusBar({
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
      return Material(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth_disabled,
                size: 18,
                color: palette.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  blockedReason ?? 'Event mode is off — messages will queue.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: starting ? null : onStartEventMode,
                child: starting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start'),
              ),
            ],
          ),
        ),
      );
    }
    final peerCount = status.peerCount;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  peerCount > 0
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_searching,
                  size: 16,
                  color: peerCount > 0 ? palette.live : palette.mesh,
                ),
                const SizedBox(width: 8),
                Text(
                  peerCount > 0
                      ? 'Mesh: $peerCount peer${peerCount == 1 ? '' : 's'}'
                      : 'Mesh: no peers yet · queued',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (status.siteMismatchDetected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: palette.caution,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A nearby device is using a different event/site '
                        'code — it will not connect.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStateIcon extends StatelessWidget {
  const _DeliveryStateIcon({required this.state});

  final RoomMessageState state;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return switch (state) {
      RoomMessageState.queued => Icon(
        Icons.schedule,
        size: 16,
        color: palette.textMuted,
      ),
      RoomMessageState.sending => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      RoomMessageState.delivered => Icon(
        Icons.check_circle,
        size: 16,
        color: palette.live,
      ),
      RoomMessageState.failed => Icon(
        Icons.error_outline,
        size: 16,
        color: palette.ember,
      ),
    };
  }
}
