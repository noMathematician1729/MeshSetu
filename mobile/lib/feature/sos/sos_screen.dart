import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/providers.dart';
import '../../core/data/database.dart';
import '../../core/model/model.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../location/location_capture.dart';
import '../triage/triage_engine.dart';
import '../voice/voice_recorder.dart';
import 'sos_repository.dart';

/// The real emergency action: persist first, record voice, capture location,
/// transcribe offline, then finalize one P0 structured SOS into the outbox.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key, required this.siteId, required this.roomId});

  final String siteId, roomId;

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _textController = TextEditingController();
  final _voiceRecorder = VoiceRecorder.withCap(const Duration(seconds: 10));
  bool _sending = false;
  bool _sendFailed = false;
  String? _status;
  String? _eventId;

  @override
  void dispose() {
    _textController.dispose();
    unawaited(_voiceRecorder.dispose());
    super.dispose();
  }

  Future<void> _sendSos() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _sendFailed = false;
      _eventId = null;
      _status = 'Securing your emergency alert…';
    });

    try {
      final repo = ref.read(sosRepositoryProvider);
      final rawText = _textController.text.trim();
      final eventId = await repo.createDraft(
        SosInput(
          siteId: widget.siteId,
          roomId: widget.roomId,
          inputMode: InputMode.voice,
          rawText: rawText,
        ),
      );

      // Request this before record's microphone permission request. Android
      // can drop one of two simultaneous runtime permission dialogs.
      _setStatus('SOS draft saved · checking location permission…');
      final locationPermission = await Permission.locationWhenInUse.request();
      final locationFuture = locationPermission.isGranted
          ? const LocationCapture().capture()
          : Future.value(
              const LocationCaptureResult.failure(
                LocationFailureReason.permissionDenied,
              ),
            );
      _setStatus('SOS draft saved · recording voice for up to 10 seconds…');
      String transcript = rawText;
      var voiceStatus = 'voice unavailable';
      try {
        final opus = await _voiceRecorder.recordOpusClip();
        _setStatus('Voice captured · attaching encrypted evidence…');
        await ref
            .read(voiceRepositoryProvider)
            .attachToSos(
              sosEventId: eventId,
              siteId: widget.siteId,
              roomId: widget.roomId,
              encoded: opus,
            );
        voiceStatus = 'voice evidence queued';
      } catch (_) {
        voiceStatus = 'voice unavailable';
        _setStatus('Voice unavailable · sending available SOS data…');
      }

      final locationResult = await locationFuture;
      final location = locationResult.location;
      final triage = await TriageEngine(SafetyRules()).triage(transcript);
      await repo.attachTriage(eventId, triage);
      if (location != null) await repo.attachLocation(eventId, location);
      await repo.finalizeAndEnqueue(eventId);

      if (!mounted) return;
      setState(() {
        _sending = false;
        _eventId = eventId;
        _status =
            'SOS saved locally · Event Mode will relay it when ready · '
            '${locationResult.status} · $voiceStatus';
        _textController.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendFailed = true;
          _status = 'SOS failed after draft persistence: $error';
        });
      }
    }
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return MeshPage(
      title: 'Send SOS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MeshStatusPill(
            label: 'Encrypted emergency packet',
            icon: Icons.lock_outline,
            tone: MeshStatusTone.critical,
          ),
          const SizedBox(height: MeshSpace.md),
          const Text(
            'Tap once, speak naturally, and the app will attach offline '
            'transcription and best-effort GPS before relaying the SOS.',
          ),
          const SizedBox(height: MeshSpace.md),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Optional text fallback',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: MeshSpace.md),
          MeshFullWidthButton(
            icon: Icons.sos,
            busy: _sending,
            onPressed: _sendSos,
            label: _sending ? 'Recording / sending…' : 'Send emergency SOS',
          ),
          if (_status != null) ...[
            const SizedBox(height: MeshSpace.md),
            _SosTransmissionPanel(
              status: _status!,
              sending: _sending,
              failed: _sendFailed,
              queued: _eventId != null,
            ),
          ],
          if (_eventId case final eventId?) ...[
            const SizedBox(height: 8),
            StreamBuilder<OutboxEvent?>(
              stream: (db.select(
                db.outboxEvents,
              )..where((t) => t.eventId.equals(eventId))).watchSingleOrNull(),
              builder: (context, snapshot) => Text(
                _deliveryLabel(snapshot.data?.state),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _deliveryLabel(String? state) => switch (state) {
    'ready' => 'Delivery: saved on this phone; waiting for Event Mode.',
    'relaying' =>
      'Delivery: queued for mesh; waiting for a peer acknowledgement.',
    'acked' => 'Delivery: acknowledged by a mesh peer.',
    'expired' => 'Delivery: no peer acknowledgement before expiry.',
    'failed' => 'Delivery: local relay failed; restart Event Mode and retry.',
    _ => 'Delivery: preparing SOS for local storage.',
  };
}

class _SosTransmissionPanel extends StatelessWidget {
  const _SosTransmissionPanel({
    required this.status,
    required this.sending,
    required this.failed,
    required this.queued,
  });

  final String status;
  final bool sending;
  final bool failed;
  final bool queued;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final (icon, color, label, title) = switch ((sending, failed, queued)) {
      (true, _, _) => (
        Icons.emergency_share_outlined,
        palette.ember,
        'Emergency transmission active',
        'Preparing your SOS',
      ),
      (_, true, _) => (
        Icons.error_outline,
        palette.ember,
        'Emergency alert needs attention',
        'SOS could not be queued',
      ),
      (_, _, true) => (
        Icons.check_circle_outline,
        palette.live,
        'Emergency alert secured',
        'SOS ready for relay',
      ),
      _ => (Icons.info_outline, palette.textMuted, 'SOS update', 'SOS status'),
    };

    return AnimatedContainer(
      duration: MeshMotion.standard,
      curve: MeshMotion.easeOut,
      child: MeshCard(
        tint: color.withValues(alpha: 0.08),
        child: Semantics(
          liveRegion: true,
          label: '$label. $status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: sending
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: color,
                            ),
                          )
                        : Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: MeshSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MeshMicroLabel(label, color: color),
                        const SizedBox(height: MeshSpace.xs),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MeshSpace.md),
              Text(status, style: Theme.of(context).textTheme.bodyMedium),
              if (sending) ...[
                const SizedBox(height: MeshSpace.md),
                const Divider(height: 1),
                const MeshEmergencyStep(
                  title: 'Emergency packet is protected',
                  detail: 'Your alert is saved on this phone before relay.',
                  complete: true,
                ),
                MeshEmergencyStep(
                  title: 'Preparing offline delivery',
                  detail: 'Voice, location, and triage are being attached.',
                  complete: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
