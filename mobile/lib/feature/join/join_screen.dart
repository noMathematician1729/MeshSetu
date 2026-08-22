import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import 'manifest.dart';
import '../rooms/room_chat_screen.dart';

/// Mesh Code / QR join screen (Bible §9.3, `feature/join`). Typed code and
/// QR scan both resolve to the same [JoinResult] path.
class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key, this.onJoined, this.createRoomOnly = false});

  final ValueChanged<String?>? onJoined;
  final bool createRoomOnly;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _codeController = TextEditingController();
  String? _error;
  bool _scanning = false;
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(joinRepositoryProvider)
        .parseAndValidateTypedCode(_codeController.text);
    if (result is JoinOk) {
      ref.read(userRolesProvider.notifier).state = const {'public'};
    }
    await _handleResult(result);
  }

  Future<void> _createLocalEvent() async {
    if (_scanning) setState(() => _scanning = false);
    final siteName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateEventSheet(),
    );
    if (siteName == null || siteName.isEmpty || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final manifest = await ref
          .read(joinRepositoryProvider)
          .createLocalEvent(siteName: siteName);
      ref.read(userRolesProvider.notifier).state = const {'authority'};
      refreshActiveSite(ref);
      if (!mounted) return;
      setState(() => _submitting = false);
      await _announceRoomJoin(manifest, manifest.rooms.first.roomId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created ${manifest.siteName}')));
      widget.onJoined?.call(manifest.rooms.first.roomId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create event: $error';
      });
    }
  }

  Future<void> _announceRoomJoin(EventManifest manifest, String roomId) async {
    try {
      final profile = await ref.read(onboardingRepositoryProvider).load();
      if (profile == null) return;
      await ref
          .read(roomRepositoryProvider(manifest.siteId))
          .announceMember(
            roomId: roomId,
            memberId: profile.profileId,
            displayName: profile.name,
          );
    } catch (_) {
      // Joining remains available when an optional presence update cannot queue.
    }
  }

  Future<void> _handleQr(String raw) async {
    if (!_scanning) return;
    setState(() => _scanning = false);
    final result = await ref
        .read(joinRepositoryProvider)
        .parseAndValidateQr(raw);
    if (result is JoinOk) {
      ref.read(userRolesProvider.notifier).state = const {'public'};
    }
    await _handleResult(result);
  }

  Future<void> _handleResult(JoinResult result) async {
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result) {
      case JoinOk(:final manifest, :final roomId):
        refreshActiveSite(ref);
        if (roomId != null) unawaited(_announceRoomJoin(manifest, roomId));
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Joined ${manifest.siteName}')));
        final onJoined = widget.onJoined;
        if (onJoined != null) {
          onJoined(roomId);
        } else {
          var room = manifest.rooms.first;
          for (final candidate in manifest.rooms) {
            if (candidate.roomId == roomId) {
              room = candidate;
              break;
            }
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RoomChatScreen(
                siteId: manifest.siteId,
                roomId: room.roomId,
                roomName: room.name,
                role: room.role,
              ),
            ),
          );
        }
      case JoinInvalid(:final reason):
        setState(
          () => _error = reason == 'unknown_code'
              ? 'Unknown code. Enter the organizer code, scan their QR, or create an event below.'
              : 'Join failed: $reason',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return MeshPage(
      title: widget.createRoomOnly ? 'Create Room' : 'Join Room',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.createRoomOnly) ...[
            Text(
              'Enter the room code the organizer shared, or scan its QR.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: MeshSpace.md),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Room code'),
            ),
            const SizedBox(height: MeshSpace.sm),
            MeshFullWidthButton(
              label: 'Join with code',
              busy: _submitting,
              onPressed: _submitCode,
            ),
            const SizedBox(height: MeshSpace.md),
            MeshFullWidthButton(
              label: _scanning ? 'Scanning…' : 'Scan QR instead',
              icon: Icons.qr_code_scanner,
              secondary: true,
              onPressed: () => setState(() => _scanning = !_scanning),
            ),
            const SizedBox(height: MeshSpace.md),
          ] else ...[
            Text(
              'Create a room lobby, then share its QR with the people you want to join.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: MeshSpace.md),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.add_home_work_outlined),
            label: Text(
              widget.createRoomOnly ? 'Name and create room' : 'Create room',
            ),
            onPressed: _submitting ? null : _createLocalEvent,
          ),
          const SizedBox(height: MeshSpace.sm),
          Text(
            'This creates a room lobby and its join QR. Add more rooms later if needed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: MeshSpace.sm),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.ember),
            ),
          ],
          if (_scanning) ...[
            const SizedBox(height: MeshSpace.md),
            _ScannerViewport(onDetect: _handleQr),
          ],
        ],
      ),
    );
  }
}

/// Camera viewport with a framed reticle overlay so the scan target reads
/// clearly against the live camera feed, instead of a bare unadorned
/// [MobileScanner].
class _ScannerViewport extends StatefulWidget {
  const _ScannerViewport({required this.onDetect});

  final ValueChanged<String> onDetect;

  @override
  State<_ScannerViewport> createState() => _ScannerViewportState();
}

class _ScannerViewportState extends State<_ScannerViewport> {
  late final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(MeshRadius.lg),
      child: SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final raw = capture.barcodes.first.rawValue;
                if (raw != null) widget.onDetect(raw);
              },
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ReticlePainter(color: palette.ember),
              ),
            ),
            Positioned(
              bottom: MeshSpace.md,
              left: 0,
              right: 0,
              child: Center(
                child: MeshStatusPill(
                  label: 'Point at the organizer\'s QR',
                  icon: Icons.center_focus_strong_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.62;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final corner = side * 0.16;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    drawCorner(
      rect.topLeft,
      Offset(corner, 0),
      Offset(0, corner),
    );
    drawCorner(
      rect.topRight,
      Offset(-corner, 0),
      Offset(0, corner),
    );
    drawCorner(
      rect.bottomLeft,
      Offset(corner, 0),
      Offset(0, -corner),
    );
    drawCorner(
      rect.bottomRight,
      Offset(-corner, 0),
      Offset(0, -corner),
    );

    // Darken outside the reticle so the target area reads as a cutout.
    final scrim = Paint()..color = const Color(0x66000000);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      scrim,
    );
  }

  @override
  bool shouldRepaint(_ReticlePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet();

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
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
              hintText: 'e.g. Campus Safety Drill',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: MeshSpace.lg),
          MeshFullWidthButton(label: 'Create', onPressed: _submit),
        ],
      ),
    ),
  );
}
