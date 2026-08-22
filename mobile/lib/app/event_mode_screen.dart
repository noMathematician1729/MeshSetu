// ignore_for_file: unused_element, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/ble/device_sms_service.dart';
import '../core/ble/sos_advertisement.dart';
import '../core/model/model.dart';
import '../feature/gateway/gateway_bridge.dart';
import '../feature/home/emergency_home_screen.dart';
import '../feature/join/join_screen.dart';
import '../feature/location/location_capture.dart';
import '../feature/onboarding/onboarding_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/rooms/room_chat_screen.dart';
import '../feature/rooms/rooms_screen.dart';
import '../feature/sos/sos_payload.dart';
import '../feature/sos/sos_repository.dart';
import '../feature/sos/sos_screen.dart';
import '../feature/sos/emergency_active_screen.dart';
import '../feature/voice/voice_recorder.dart';
import '../ui/components/mesh_components.dart';
import '../ui/theme/mesh_tokens.dart';
import '../ui/theme/theme_controller.dart';
import 'emergency_gestures.dart';
import 'mesh_bridge.dart';
import 'mesh_bridge_client.dart';
import 'mesh_event_controller.dart';
import 'mesh_event_task.dart';
import 'event_mode_launcher.dart';
import 'incident_summary.dart';
import 'providers.dart';
import 'sos_alert_notifications.dart';
import 'sos_delivery.dart';
import 'sos_incident_navigator.dart';

/// Port of `in.meshsetu.app.MainActivity` (Kotlin `MainActivity.kt`), plus
/// the Dev B navigation entry point into Join/Rooms/SOS once the mesh is up.
class EventModeScreen extends ConsumerStatefulWidget {
  const EventModeScreen({super.key});

  @override
  ConsumerState<EventModeScreen> createState() => _EventModeScreenState();
}

class _EventModeScreenState extends ConsumerState<EventModeScreen> {
  bool _eventModeActive = false;
  bool _debugLossEnabled = false;
  String _status = 'MeshSetu\nEvent mode is off';
  String _meshStatus = 'stopped';
  String _lastMetric = 'none';
  String _lastConnection = 'none';
  String _advertisingStatus = 'unknown';
  String _nearestBeacon = 'none';
  String _zone = 'unknown';
  String _sttStatus = 'not run';
  bool _sttTesting = false;
  bool _sosPacketSending = false;
  SosEmergencyType _selectedEmergencyType = SosEmergencyType.general;
  String _sosDescription = '';
  bool _gestureConfirmationShowing = false;
  bool _gestureServiceEnabled = false;
  StreamSubscription<SosEmergencyType>? _typedSosGestureSubscription;
  List<Map<String, dynamic>> _peerDebug = const [];
  final Map<String, int> _scanStats = {};
  String _lastReceived = 'none';
  String? _receivedSosReporter;
  String? _receivedSosLocation;
  String? _receivedSosContact;
  String? _receivedSosPeer;
  int? _receivedSosHopCount;
  int? _receivedSosHopLimit;
  String? _receivedSosEventId;
  int? _receivedSosObjectId;
  String? _receivedSosSiteId;
  int? _foregroundEphemeralId;
  MeshBridgeClient? _bridgeClient;
  SosDeliveryTracker? _activeSosTracker;
  String? _preparingSosEventId;
  final List<SosDeliveryEvent> _pendingSosDeliveryEvents = [];
  late final TextEditingController _adminServerController;
  late final TextEditingController _gatewayKeyController;
  final VoiceRecorder _sttRecorder = VoiceRecorder.withCap(
    const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _adminServerController = TextEditingController(
      text: ref.read(gatewayUrlProvider),
    );
    _gatewayKeyController = TextEditingController(
      text: ref.read(gatewayDemoKeyProvider),
    );
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    EmergencyGestureSettings.startListeningForTypedSosGestures();
    _typedSosGestureSubscription = EmergencyGestureSettings.typedSosGestures
        .listen((emergencyType) {
          unawaited(_confirmGestureSosPacket(emergencyType));
        });
    unawaited(_consumePendingTypedSosGesture());
    unawaited(EventModeLauncher.initialize());
    unawaited(_refreshGestureServiceState());
    unawaited(_restoreOrStartEventMode());
  }

  Future<void> _restoreOrStartEventMode() async {
    if (await FlutterForegroundTask.isRunningService) {
      await _restoreServiceState();
    } else {
      await _startEventMode();
    }
  }

  Future<void> _consumePendingTypedSosGesture() async {
    try {
      final emergencyType =
          await EmergencyGestureSettings.takePendingTypedSosGesture();
      if (emergencyType != null) await _confirmGestureSosPacket(emergencyType);
    } catch (_) {
      // Native gesture support is Android-only; direct red SOS remains usable.
    }
  }

  Future<void> _confirmGestureSosPacket(SosEmergencyType emergencyType) async {
    if (!mounted || _gestureConfirmationShowing || _sosPacketSending) return;
    _gestureConfirmationShowing = true;
    try {
      setState(() {
        _status =
            'MeshSetu\n${emergencyType.label} gesture detected\nConfirm or cancel the SOS countdown';
      });
      // This is intentionally the typed red-SOS confirmation path. It never
      // invokes the separate CEAL identity-SOS route.
      await _confirmAndSendSosPacket(emergencyType);
    } finally {
      _gestureConfirmationShowing = false;
    }
  }

  Future<void> _refreshGestureServiceState() async {
    try {
      final enabled = await EmergencyGestureSettings.isEnabled();
      if (mounted) setState(() => _gestureServiceEnabled = enabled);
    } catch (_) {
      // Gesture enrollment is Android-only; the typed SOS UI remains usable.
    }
  }

  Future<void> _openGestureSettings() async {
    await EmergencyGestureSettings.openSettings();
    // Settings returns asynchronously; refresh immediately and again when the
    // user returns to this screen in a later build/session.
    await _refreshGestureServiceState();
  }

  Future<void> _restoreServiceState() async {
    if (!await FlutterForegroundTask.isRunningService || !mounted) return;
    setState(() {
      _eventModeActive = true;
      _status = 'MeshSetu\nEvent mode active\nBLE relay service running';
    });
    await _startBridgeForActiveSite();
  }

  void _onTaskData(Object data) {
    if (!mounted || data is! Map) return;
    switch (data['status']) {
      case 'started':
        _foregroundEphemeralId = data['localEphemeralId'] as int?;
        setState(() {
          _eventModeActive = true;
          _status = 'MeshSetu\nEvent mode active\nBLE relay service running';
        });
        unawaited(_startBridgeForActiveSite());
      case 'stopped':
        setState(() {
          _eventModeActive = false;
          _debugLossEnabled = false;
          _meshStatus = 'stopped';
          _peerDebug = const [];
          _nearestBeacon = 'none';
          _zone = 'unknown';
          _scanStats.clear();
          _lastReceived = 'none';
          _lastConnection = 'none';
          _advertisingStatus = 'unknown';
          // Preserve an error message already set by the 'error' case so
          // the user can read why event mode stopped instead of seeing a
          // generic "Event mode is off".
          if (_status ==
                  'MeshSetu\nEvent mode active\nBLE relay service running' ||
              _status == 'MeshSetu\nStarting BLE relay service' ||
              _status == 'MeshSetu\nEvent mode is off' ||
              !_status.contains('\n')) {
            _status = 'MeshSetu\nEvent mode is off';
          }
        });
        unawaited(_bridgeClient?.dispose());
        _bridgeClient = null;
        _bridgeClientSiteStarted = false;
        ref.read(meshBridgeClientProvider.notifier).state = null;
      case 'error':
        setState(() {
          _eventModeActive = false;
          _debugLossEnabled = false;
          _status = 'MeshSetu\n${data['message']}';
        });
        unawaited(FlutterForegroundTask.stopService());
      case 'sos_failed':
        setState(() {
          _status =
              'MeshSetu\n${data['message'] ?? 'Test SOS could not queue'}';
        });
      case 'compact_sos_received':
        final packet = data['dedupeKey'] ?? 'unknown packet';
        setState(() {
          _status =
              'MeshSetu\nCompact SOS received over BLE\nPacket $packet\nForwarding to admin and emergency contacts';
        });
        unawaited(_forwardReceivedCealSos(data));
        // Belt-and-suspenders: also send device-native SMS immediately from
        // this phone's SIM so emergency contacts are notified even when the
        // admin server is unreachable or internet is down on the relay device.
        unawaited(_sendDeviceSmsForCompactSos(data));
      case 'compact_sos_notification_failed':
        setState(() {
          _status =
              'MeshSetu\n${data['message'] ?? 'SOS received by Bluetooth, but notification display failed'}';
        });
      case 'mesh_test_origin_submitted':
        final envelopeJson = data['envelope'];
        if (envelopeJson is Map) {
          unawaited(
            _forwardTestSosToAdmin(
              MeshBridge.envelopeFromJson(
                envelopeJson.cast<Object?, Object?>(),
              ),
            ),
          );
        }
      case 'mesh_received':
        final receivedJson = data['received'];
        if (receivedJson is Map) {
          _recordReceivedSos(
            MeshBridge.receivedFromJson(receivedJson.cast<Object?, Object?>()),
          );
        }
      case 'mesh_status':
        setState(() => _meshStatus = '${data['value'] ?? 'unknown'}');
      case 'mesh_metric':
        final metrics = data['metrics'];
        if (metrics is List) {
          setState(() {
            for (final rawMetric in metrics) {
              if (rawMetric is! Map) continue;
              final metric = Map<String, dynamic>.from(rawMetric);
              final kind = '${metric['kind'] ?? 'unknown'}';
              final value = metric['value'];
              if (kind.startsWith('scan_') && value is num) {
                _scanStats[kind] = value.toInt();
              }
              final peer = metric['peerId'];
              final detail = metric['detail'];
              _lastMetric =
                  '$kind'
                  '${peer == null ? '' : ' ($peer)'}'
                  '${detail == null ? '' : ': $detail'}';
              if (kind == 'advertising_started') {
                _advertisingStatus = 'starting';
              } else if (kind == 'advertising_verified' ||
                  kind == 'advertising_reasserted') {
                _advertisingStatus = 'verified';
              } else if (kind == 'advertising_degraded') {
                _advertisingStatus = 'scan-only (advertising unavailable)';
              } else if (kind == 'advertising_failed' ||
                  kind == 'advertising_reassert_failed') {
                _advertisingStatus =
                    'failed${detail == null ? '' : ': $detail'}';
              }
              if (kind == 'peer_connect_failed' ||
                  kind == 'peer_connected' ||
                  kind == 'peer_session_ready' ||
                  kind.startsWith('gatt_') ||
                  kind.startsWith('server_') ||
                  kind.startsWith('advertising_') ||
                  kind == 'send_failed' ||
                  kind == 'control_send_failed' ||
                  kind == 'custody_ack_sent' ||
                  kind == 'custody_ack_received' ||
                  kind == 'custody_ack_send_failed' ||
                  kind == 'ack_timeout') {
                _lastConnection = _friendlyConnectionMetric(kind, peer, detail);
              }
              if (kind == 'object_received') {
                _lastReceived =
                    '${metric['objectId'] ?? '?'} · ${value ?? '?'} bytes'
                    '${peer == null ? '' : ' from $peer'}';
              }
            }
          });
        }
      case 'mesh_peers':
        final peers = data['peers'];
        if (peers is List) {
          setState(
            () => _peerDebug = [
              for (final peer in peers)
                if (peer is Map) Map<String, dynamic>.from(peer),
            ],
          );
        }
      case 'mesh_beacons':
        final beacons = data['beacons'];
        if (beacons is List && beacons.isNotEmpty && beacons.first is Map) {
          final beacon = Map<String, dynamic>.from(beacons.first as Map);
          setState(
            () => _nearestBeacon =
                '${beacon['anchorId']} (${beacon['rssi'] ?? '?'} dBm)',
          );
        } else if (beacons is List && beacons.isEmpty) {
          setState(() => _nearestBeacon = 'none');
        }
      case 'mesh_zone':
        setState(
          () => _zone =
              '${data['zone'] ?? 'unknown'} (${data['uncertainty'] ?? 'unknown'})',
        );
    }
  }

  String _friendlyConnectionMetric(String kind, Object? peer, Object? detail) {
    final peerSuffix = peer == null ? '' : ' (${peer.toString()})';
    final description = switch (kind) {
      'gatt_server_connected' =>
        'Peer connected to this phone as a GATT server',
      'gatt_server_disconnected' =>
        'Peer disconnected from this phone as a GATT server',
      'advertising_started' => 'BLE advertising start requested',
      'advertising_verified' => 'BLE advertising verified by platform',
      'advertising_reasserted' => 'BLE advertising reasserted and verified',
      'advertising_failed' => 'BLE advertising verification failed',
      'advertising_reassert_failed' => 'BLE advertising reassert failed',
      'peer_connected' => 'Mesh peer connected',
      'peer_connect_failed' => 'Could not connect to mesh peer',
      'peer_session_ready' => 'Mesh peer session ready',
      'send_failed' => 'Mesh send failed',
      'control_send_failed' => 'Mesh acknowledgement/control send failed',
      'custody_ack_sent' => 'Custody acknowledgement sent to peer',
      'custody_ack_received' => 'Custody acknowledgement received from peer',
      'custody_ack_send_failed' =>
        'Could not send custody acknowledgement; sender will retry',
      'ack_timeout' => 'No peer acknowledgement received; retrying',
      _ => kind,
    };
    return '$description$peerSuffix'
        '${detail == null ? '' : ': ${detail.toString()}'}';
  }

  void _recordReceivedSos(ReceivedObject received) {
    if (received.envelope.payloadType != PayloadType.structuredSos) return;
    try {
      final sos = StructuredSosPayload.decode(received.envelope.payload);
      final reporter = sos.reporter;
      final location = sos.latitude == null || sos.longitude == null
          ? 'Location unavailable'
          : '${sos.latitude!.toStringAsFixed(5)}, '
                '${sos.longitude!.toStringAsFixed(5)}'
                '${sos.accuracyM == null ? '' : ' · ±${sos.accuracyM!.round()} m'}';
      setState(() {
        _receivedSosReporter = reporter?.name ?? 'Unknown sender';
        _receivedSosLocation = location;
        _receivedSosContact = reporter == null
            ? null
            : '${reporter.primaryContactName} · ${reporter.primaryContactPhone}'
                  '${reporter.bloodGroup.isEmpty ? '' : ' · ${reporter.bloodGroup}'}';
        _receivedSosPeer = received.peerId;
        _receivedSosHopCount = received.envelope.hopCount;
        _receivedSosHopLimit = received.envelope.hopLimit;
        _receivedSosEventId = received.envelope.eventId;
        _receivedSosObjectId = received.envelope.objectId;
        _receivedSosSiteId = received.envelope.siteId;
      });
    } catch (_) {
      // Only complete authenticated structured SOS payloads are displayed.
    }
  }

  Future<void> _forwardTestSosToAdmin(MeshEnvelope envelope) async {
    if (!ref.read(gatewayEnabledProvider)) {
      if (mounted) {
        setState(() => _status = 'MeshSetu\nTest SOS sent over BLE only');
      }
      return;
    }
    try {
      final bridge = GatewayBridge(
        baseUrl: Uri.parse(ref.read(gatewayUrlProvider)),
        demoKey: ref.read(gatewayDemoKeyProvider),
      );
      await bridge.postToDashboard(bridge.testSosJson(envelope));
      if (mounted) {
        setState(() => _status = 'MeshSetu\nTest SOS sent to admin server');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'MeshSetu\nAdmin test send failed: $error');
      }
    }
  }

  MeshSosAdvertisement? _compactAlertFromData(Map data) {
    final siteFingerprint = data['siteFingerprint'] as int?;
    final originId = data['originId'] as int?;
    final sequence = data['sequence'] as int?;
    if (siteFingerprint == null || originId == null || sequence == null) {
      return null;
    }
    return MeshSosAdvertisement(
      siteFingerprint: siteFingerprint,
      originId: originId,
      sequence: sequence,
      flags: data['flags'] as int? ?? MeshSosAdvertisement.alertFlag,
      ttl: data['ttl'] as int? ?? 0,
      reporterUidHex: MeshSosAdvertisement.normalizeReporterUid(
        data['reporterUid'] as String?,
      ),
    );
  }

  Future<void> _showCompactSosFallback(
    Map data, {
    required String availability,
  }) async {
    final alert = _compactAlertFromData(data);
    final dedupeKey = data['dedupeKey'] as String?;
    if (alert == null || dedupeKey == null) return;
    await SosAlertNotifications.show(
      id: SosAlertNotifications.idForKey(dedupeKey),
      title: 'SOS RECEIVED · COMPACT',
      body: SosAlertNotifications.compactPacketBody(
        alert,
        availability: availability,
      ),
      payload: SosIncidentNavigator.payloadForCompactAlert(alert),
    );
  }

  Future<void> _forwardReceivedCealSos(Map data) async {
    final url = ref.read(gatewayUrlProvider);
    final key = ref.read(gatewayDemoKeyProvider);
    if (url.isEmpty || key.isEmpty) {
      await _showCompactSosFallback(
        data,
        availability:
            'No control-room connection is configured; relay this packet over Bluetooth.',
      );
      return;
    }
    try {
      final originId = data['originId'] as int?;
      final sequence = data['sequence'] as int?;
      final dedupeKey = data['dedupeKey'] as String?;
      // A v2 advert carries the sender's full 6-byte UID. Older phones only
      // send 4 bytes of it, so fall back to a resolvable prefix.
      final advertisedUid = MeshSosAdvertisement.normalizeReporterUid(
        data['reporterUid'] as String?,
      );
      final reporterUid = advertisedUid.isNotEmpty
          ? advertisedUid
          : originId != null
          ? originId.toRadixString(16).padLeft(8, '0')
          : '';
      if (reporterUid.isEmpty) return;
      final bridge = GatewayBridge(baseUrl: Uri.parse(url), demoKey: key);
      // The detail request itself is the reachability check. A separate health
      // probe incorrectly marked phones with working cellular data as offline
      // when that probe timed out or the control room was waking up.
      final site = await ref.read(joinRepositoryProvider).activeManifest();
      final (success, detail, body) = await bridge.forwardCealSos(
        reporterUid: reporterUid,
        siteId: site?.siteId ?? MeshEventController.demoSiteId,
        flags: data['flags'] as int? ?? MeshSosAdvertisement.alertFlag,
        originId: originId,
        sequence: sequence,
      );
      final resolved = success && body?['event'] is Map;
      if (resolved && dedupeKey != null) {
        await _showResolvedSosDetails(dedupeKey: dedupeKey, body: body);
      } else {
        await _showCompactSosFallback(
          data,
          availability: success
              ? 'Control room reached, but expanded details are not available yet. Keep relaying this packet.'
              : 'Verified details could not be retrieved. This compact packet remains usable without internet.',
        );
      }
      if (mounted) {
        setState(
          () => _status = resolved
              ? 'MeshSetu\nSOS details resolved from control room ✓'
              : 'MeshSetu\nCompact SOS received · $detail',
        );
      }
    } catch (error) {
      await _showCompactSosFallback(
        data,
        availability:
            'Verified detail lookup is unavailable; relay this compact packet over Bluetooth.',
      );
      if (mounted) {
        setState(() => _status = 'MeshSetu\nCompact SOS relay error: $error');
      }
    }
  }

  /// Sends a device-native SMS from this phone's SIM to every emergency
  /// contact in the locally stored onboarding profile when a compact SOS is
  /// relayed through this device.
  ///
  /// This fires in addition to the admin-server forwarding path so contacts
  /// are reached even when the internet gateway is unavailable. The SMS is
  /// sent from this relay device's own number — no API key or billing account
  /// required — using Android's [SmsManager] via [DeviceSmsService].
  Future<void> _sendDeviceSmsForCompactSos(Map data) async {
    try {
      final profile = await ref.read(onboardingRepositoryProvider).load();
      if (profile == null || profile.emergencyContacts.isEmpty) return;

      // Build a compact body with whatever location the compact alert carries.
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      final flags = data['flags'] as int? ?? 0;
      // Derive a human-readable emergency type from the SOS flags using the
      // same mapping the admin server uses for CEAL alerts.
      final emergencyType = _emergencyTypeLabel(flags);

      final body = DeviceSmsService.buildBody(
        reporterName: 'Unknown — nearby SOS',
        latitude: lat,
        longitude: lon,
        emergencyType: emergencyType,
      );

      final phones = [
        for (final contact in profile.emergencyContacts) contact.phone,
      ];

      final sent = await DeviceSmsService.sendToAll(phones, body);
      if (sent > 0 && mounted) {
        setState(
          () => _status =
              'MeshSetu\nSOS relayed · $sent contact${sent == 1 ? '' : 's'} notified via device SMS',
        );
      }
    } catch (_) {
      // Device SMS failure must never interrupt the BLE relay or the admin
      // forwarding path.
    }
  }

  static String _emergencyTypeLabel(int flags) {
    // Mirrors the CEAL flag→type mapping in admin/server/src/server.ts.
    const types = [
      'general',
      'fire',
      'crime',
      'kidnap',
      'medical',
      'natural_disaster',
    ];
    final index = (flags >> 2) & 0x0f;
    return index < types.length ? types[index] : 'general';
  }

  /// Replaces the "you are relaying" alert with the decrypted/resolved
  /// incident detail once the control room answers. This is what an
  /// internet-connected peer sees instead of a generic alert.
  Future<void> _showResolvedSosDetails({
    required String dedupeKey,
    required Map<String, Object?>? body,
  }) async {
    final event = body?['event'];
    if (event is! Map) return;
    final incident = event.cast<String, Object?>();
    final eventId = incident['event_id'] as String?;
    await SosAlertNotifications.show(
      id: SosAlertNotifications.idForKey(dedupeKey),
      title: 'SOS RECEIVED',
      body: describeIncident(incident),
      payload: eventId == null
          ? null
          : SosIncidentNavigator.payloadForEvent(eventId),
    );
  }

  Future<void> _startEventMode() async {
    if (await FlutterForegroundTask.isRunningService) {
      if (mounted) {
        setState(() {
          _eventModeActive = true;
          _status = 'MeshSetu\nEvent mode active\nBLE relay service running';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _status = 'MeshSetu\nStarting BLE relay service');
    }
    final result = await EventModeLauncher.start(
      taskCallback: meshEventTaskCallback,
      onStatus: (message) {
        if (mounted) setState(() => _status = 'MeshSetu\n$message');
      },
      onMeshSiteConfigurationNeeded: _saveActiveMeshConfiguration,
    );
    if (!mounted) return;
    switch (result) {
      case EventModeLaunchResult.alreadyRunning:
      case EventModeLaunchResult.started:
        setState(() {
          _eventModeActive = true;
          _status = 'MeshSetu\nStarting BLE relay service';
        });
      case EventModeLaunchResult.failure:
        break;
    }
  }

  Future<void> _stopEventMode() async {
    await FlutterForegroundTask.stopService();
    if (!mounted) return;
    setState(() {
      _eventModeActive = false;
      _debugLossEnabled = false;
      _meshStatus = 'stopped';
      _peerDebug = const [];
      _nearestBeacon = 'none';
      _zone = 'unknown';
      _scanStats.clear();
      _lastConnection = 'none';
      _advertisingStatus = 'unknown';
      _lastReceived = 'none';
      _receivedSosReporter = null;
      _receivedSosLocation = null;
      _receivedSosContact = null;
      _receivedSosPeer = null;
      _receivedSosHopCount = null;
      _receivedSosHopLimit = null;
      _status = 'MeshSetu\nEvent mode is off';
    });
  }

  Future<void> _sendTestSos() async {
    setState(() => _status = 'MeshSetu\nTest SOS queued');
    FlutterForegroundTask.sendDataToTask('send_test_sos');
  }

  Future<void> _chooseAndSendSosPacket() async {
    final emergencyType = await Navigator.of(context).push<SosEmergencyType>(
      MaterialPageRoute(builder: (_) => const _SosTypeSelectionScreen()),
    );
    if (emergencyType != null && mounted) {
      await _confirmAndSendSosPacket(emergencyType);
    }
  }

  Future<void> _chooseEmergencyType() async {
    final emergencyType = await Navigator.of(context).push<SosEmergencyType>(
      MaterialPageRoute(builder: (_) => const _SosTypeSelectionScreen()),
    );
    if (emergencyType != null && mounted) {
      setState(() => _selectedEmergencyType = emergencyType);
    }
  }

  Future<void> _describeSos() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _DescribeSosSheet(initialText: _sosDescription),
    );
    if (value != null && mounted) setState(() => _sosDescription = value);
  }

  Future<void> _confirmAndSendSosPacket(SosEmergencyType emergencyType) async {
    if (_sosPacketSending) return;
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted) return;
    if (profile == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SosCountdownDialog(),
    );
    if (confirmed == true) await _sendSosPacket(emergencyType);
  }

  Future<void> _sendSosPacket(SosEmergencyType emergencyType) async {
    setState(() {
      _sosPacketSending = true;
      _status = 'MeshSetu\nPreparing emergency SOS packet…';
    });
    try {
      final site = await ref.read(joinRepositoryProvider).activeManifest();
      final repo = ref.read(sosRepositoryProvider);
      final eventId = await repo.createDraft(
        SosInput(
          siteId: site?.siteId ?? MeshEventController.demoSiteId,
          roomId: site?.rooms.isNotEmpty == true
              ? site!.rooms.first.roomId
              : 'public',
          inputMode: InputMode.tap,
          rawText: _sosDescription,
          priority: PriorityBand.p0Critical,
          emergencyType: emergencyType,
        ),
      );
      _preparingSosEventId = eventId;
      final locationEnabled = ref.read(locationSharingProvider);
      final permission = locationEnabled
          ? await Permission.locationWhenInUse.request()
          : PermissionStatus.denied;
      final locationResult = locationEnabled && permission.isGranted
          ? await const LocationCapture().capture()
          : const LocationCaptureResult.failure(
              LocationFailureReason.permissionDenied,
            );
      if (locationResult.location case final location?) {
        await repo.attachLocation(eventId, location);
      }
      await repo.finalizeAndEnqueue(eventId);
      final row =
          await (ref
                  .read(databaseProvider)
                  .select(ref.read(databaseProvider).outboxEvents)
                ..where((event) => event.eventId.equals(eventId)))
              .getSingle();
      final objectId = row.objectId;
      if (objectId == null) {
        throw StateError('SOS was finalized without a transport object ID');
      }
      _activeSosTracker?.dispose();
      final tracker = SosDeliveryTracker(
        SosDeliveryStatus(
          eventId: eventId,
          objectId: objectId,
          phase: SosDeliveryPhase.queued,
          locationStatus: locationResult.status,
          detail:
              'SOS saved locally and queued for the emergency mesh. Delivery is not confirmed yet.',
        ),
      );
      _activeSosTracker = tracker;
      for (final event in _pendingSosDeliveryEvents) {
        tracker.apply(event);
      }
      _pendingSosDeliveryEvents.clear();
      _preparingSosEventId = null;
      if (mounted) {
        final adminForwardingConfigured =
            ref.read(gatewayEnabledProvider) &&
            ref.read(gatewayUrlProvider).isNotEmpty &&
            ref.read(gatewayDemoKeyProvider).isNotEmpty;
        setState(() {
          _status =
              'MeshSetu\nSOS packet queued · ${locationResult.status}\n'
              '${emergencyType.label} will broadcast on mesh submission'
              '${adminForwardingConfigured ? '\nAdmin forwarding pending…' : '\nMesh-only: configure admin forwarding to relay online'}';
        });
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmergencyActiveScreen(
              locationStatus: locationResult.status,
              meshActive: _eventModeActive,
              delivery: tracker,
            ),
          ),
        );
        if (identical(_activeSosTracker, tracker)) {
          tracker.dispose();
          _activeSosTracker = null;
        }
        if (mounted) {
          setState(() {
            _selectedEmergencyType = SosEmergencyType.general;
            _sosDescription = '';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'MeshSetu\nSOS packet failed: $error');
      }
    } finally {
      _preparingSosEventId = null;
      if (_activeSosTracker == null) _pendingSosDeliveryEvents.clear();
      if (mounted) setState(() => _sosPacketSending = false);
    }
  }

  Future<void> _editProfile() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(initialProfile: profile),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _confirmAndSendCealSos() async {
    final profile = await ref.read(onboardingRepositoryProvider).load();
    if (!mounted) return;
    if (profile == null) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SosCountdownDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _status = 'MeshSetu\nPreparing identity SOS details…');
    try {
      final locationResult = await _queueIdentitySosDetails();
      final location = locationResult.location;
      // Convert the first 4 bytes of the 6-byte reporterUid hex into an int
      // to use as the BLE advertisement originId (CEAL's pseudonymous UID).
      final uidHex = profile.reporterUid.padRight(8, '0').substring(0, 8);
      final originId = int.parse(uidHex, radix: 16);
      FlutterForegroundTask.sendDataToTask({
        'broadcast_ceal_sos': true,
        'originId': originId,
        'reporterUid': profile.reporterUid,
        'flags': MeshSosAdvertisement.flagsFor(SosEmergencyType.general),
      });
      // Also forward to the admin backend for UID→profile resolution.
      // Construct the bridge directly from provider state rather than relying
      // on _bridgeClient (which may not yet be initialized).
      final url = ref.read(gatewayUrlProvider);
      final key = ref.read(gatewayDemoKeyProvider);
      if (url.isNotEmpty && key.isNotEmpty) {
        final bridge = GatewayBridge(baseUrl: Uri.parse(url), demoKey: key);
        final (success, detail, _) = await bridge.forwardCealSos(
          reporterUid: profile.reporterUid,
          siteId:
              (await ref.read(joinRepositoryProvider).activeManifest())
                  ?.siteId ??
              MeshEventController.demoSiteId,
          flags: MeshSosAdvertisement.flagsFor(SosEmergencyType.general),
          originId: originId,
          latitude: location?.latitude,
          longitude: location?.longitude,
          accuracyM: location?.accuracyM,
          locationCapturedAtMs: location?.capturedAtMs,
        );
        if (mounted) {
          setState(
            () => _status = success
                ? 'MeshSetu\nIdentity SOS broadcast ✓\n'
                      'Encrypted identity details queued · ${locationResult.status}\n'
                      'Dashboard resolved UID ${profile.reporterUid}'
                : 'MeshSetu\nIdentity SOS broadcast · details queued '
                      '(${locationResult.status}) · admin: $detail',
          );
        }
      } else {
        if (mounted) {
          setState(
            () => _status =
                'MeshSetu\nIdentity SOS broadcast · encrypted details queued '
                '(${locationResult.status})',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'MeshSetu\nCEAL SOS broadcast failed: $error');
      }
    }
  }

  Future<LocationCaptureResult> _queueIdentitySosDetails() async {
    final site = await ref.read(joinRepositoryProvider).activeManifest();
    final repo = ref.read(sosRepositoryProvider);
    final eventId = await repo.createDraft(
      SosInput(
        siteId: site?.siteId ?? MeshEventController.demoSiteId,
        roomId: site?.rooms.isNotEmpty == true
            ? site!.rooms.first.roomId
            : 'public',
        inputMode: InputMode.tap,
        rawText: 'Identity SOS',
        priority: PriorityBand.p0Critical,
      ),
    );
    final permission = await Permission.locationWhenInUse.request();
    final locationResult = permission.isGranted
        ? await const LocationCapture().capture()
        : const LocationCaptureResult.failure(
            LocationFailureReason.permissionDenied,
          );
    if (locationResult.location case final location?) {
      await repo.attachLocation(eventId, location);
    }
    await repo.finalizeAndEnqueue(eventId);
    return locationResult;
  }

  Future<void> _openSos() async {
    final site = await ref.read(joinRepositoryProvider).activeManifest();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosScreen(
          siteId: site?.siteId ?? MeshEventController.demoSiteId,
          roomId: site?.rooms.isNotEmpty == true
              ? site!.rooms.first.roomId
              : 'public',
        ),
      ),
    );
  }

  Future<void> _openJoinOrRooms() async {
    final site = await ref.read(joinRepositoryProvider).activeManifest();
    if (!mounted) return;
    if (site != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RoomsScreen()));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JoinScreen(
          onJoined: (roomId) {
            unawaited(_startBridgeForActiveSite());
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RoomsScreen(initialRoomId: roomId),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createEventAndRoom() async {
    // A site/event already exists: "create a room" should add a room to
    // it (RoomsScreen -> "Create another room"), not spin up a brand new
    // event. JoinRepository keys one row per siteId and activeManifest()
    // only ever surfaces the most recently joined/created site, so every
    // call to createLocalEvent() here was silently hiding all previously
    // created rooms behind a fresh, unrelated site.
    final existingSite = await ref
        .read(joinRepositoryProvider)
        .activeManifest();
    if (!mounted) return;
    if (existingSite != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RoomsScreen()));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JoinScreen(
          createRoomOnly: true,
          onJoined: (roomId) {
            unawaited(_startBridgeForActiveSite());
            // Route through the room lobby (QR + room/event codes) instead
            // of straight into chat: the creator needs to show the QR code
            // to other people before anyone can join.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RoomsScreen(initialRoomId: roomId),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _joinRoomScanQr() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JoinScreen(
          onJoined: (roomId) {
            unawaited(_startBridgeForActiveSite());
            unawaited(_openJoinedRoom(context, roomId));
          },
        ),
      ),
    );
  }

  Future<void> _openJoinedRoom(BuildContext context, String? roomId) async {
    final manifest = await ref.read(joinRepositoryProvider).activeManifest();
    if (!context.mounted || manifest == null || manifest.rooms.isEmpty) return;
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

  bool _bridgeClientSiteStarted = false;

  Future<void> _startBridgeForActiveSite() async {
    final site = await ref.read(joinRepositoryProvider).activeManifest();
    if (!mounted || !_eventModeActive) return;
    await _configureForegroundMeshSite(site?.siteId);
    _bridgeClient ??=
        ref.read(meshBridgeClientProvider) ??
        MeshBridgeClient(ref.read(databaseProvider));
    _bridgeClient!.onOriginForward = _onOriginForward;
    _bridgeClient!.onSosDelivery = _onSosDeliveryEvent;
    ref.read(meshBridgeClientProvider.notifier).state = _bridgeClient;
    if (!_bridgeClientSiteStarted) {
      final localEphemeralId = _foregroundEphemeralId;
      if (localEphemeralId == null) return;
      _bridgeClient!.start(
        siteId: site?.siteId ?? MeshEventController.demoSiteId,
        localEphemeralId: localEphemeralId,
      );
      _bridgeClientSiteStarted = true;
    } else if (site != null) {
      _bridgeClient!.setSiteId(site.siteId);
    }
    _applyGatewaySettings();
  }

  void _onSosDeliveryEvent(SosDeliveryEvent event) {
    if (!mounted) return;
    final tracker = _activeSosTracker;
    if (tracker == null) {
      if (event.eventId == _preparingSosEventId) {
        _pendingSosDeliveryEvents.add(event);
        if (_pendingSosDeliveryEvents.length > 8) {
          _pendingSosDeliveryEvents.removeAt(0);
        }
      }
      return;
    }
    if (tracker.value.eventId != event.eventId &&
        tracker.value.objectId != event.objectId) {
      return;
    }
    tracker.apply(event);
    final status = tracker.value;
    final message = switch (status.phase) {
      SosDeliveryPhase.queued => 'SOS saved · queued for nearby mesh relay',
      SosDeliveryPhase.broadcasting =>
        'SOS broadcasting nearby · awaiting peer acknowledgement',
      SosDeliveryPhase.confirmed => 'SOS confirmed by a nearby mesh peer',
      SosDeliveryPhase.failed => 'SOS delivery failed · ${status.detail}',
      SosDeliveryPhase.saved => 'SOS saved securely on this device',
    };
    setState(() => _status = 'MeshSetu\n$message');
  }

  void _onOriginForward(MeshEnvelope envelope, Object? error) {
    if (!mounted || envelope.payloadType != PayloadType.structuredSos) return;
    setState(() {
      _status = error == null
          ? 'MeshSetu\nP0 SOS uploaded to admin dashboard · mesh delivery still pending'
          : 'MeshSetu\nP0 SOS queued for mesh · admin forwarding unavailable';
    });
  }

  Future<void> _saveActiveMeshConfiguration() async {
    final site = await ref.read(joinRepositoryProvider).activeManifest();
    final configuration = MeshSiteConfiguration.forSite(
      site?.siteId ?? MeshEventController.demoSiteId,
    );
    await FlutterForegroundTask.saveData(
      key: meshSiteConfigurationKey,
      value: configuration.encode(),
    );
  }

  Future<void> _configureForegroundMeshSite(String? siteId) async {
    final configuration = MeshSiteConfiguration.forSite(
      siteId ?? MeshEventController.demoSiteId,
    );
    await FlutterForegroundTask.saveData(
      key: meshSiteConfigurationKey,
      value: configuration.encode(),
    );
    FlutterForegroundTask.sendDataToTask({
      'meshSiteConfiguration': configuration.encode(),
    });
  }

  void _applyGatewaySettings() {
    final enabled = ref.read(gatewayEnabledProvider);
    final url = ref.read(gatewayUrlProvider);
    final key = ref.read(gatewayDemoKeyProvider);
    final bridge = (enabled && url.isNotEmpty && key.isNotEmpty)
        ? GatewayBridge(baseUrl: Uri.parse(url), demoKey: key)
        : null;
    _bridgeClient?.gatewayBridge = bridge;
    unawaited(_applyContactAlertSettings(bridge));
  }

  /// Emergency-contact alerts are addressed to this device's own profile UID,
  /// so the backend fan-out reaches the contact even when the incident was
  /// relayed by someone else entirely.
  Future<void> _applyContactAlertSettings(GatewayBridge? bridge) async {
    try {
      final profile = await ref.read(onboardingRepositoryProvider).load();
      _bridgeClient?.configureContactAlerts(
        reporterUid: profile?.reporterUid,
        bridge: bridge,
      );
    } catch (_) {
      // Without a stored profile this device is not an emergency contact.
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    unawaited(_typedSosGestureSubscription?.cancel());
    unawaited(_bridgeClient?.dispose());
    _activeSosTracker?.dispose();
    _activeSosTracker = null;
    _preparingSosEventId = null;
    _pendingSosDeliveryEvents.clear();
    unawaited(_sttRecorder.dispose());
    _adminServerController.dispose();
    _gatewayKeyController.dispose();
    _bridgeClientSiteStarted = false;
    super.dispose();
  }

  Future<void> _runSttSmokeTest() async {
    if (_sttTesting) return;
    setState(() {
      _sttTesting = true;
      _sttStatus = 'recording 3s of raw PCM...';
    });
    try {
      final engine = ref.read(offlineSttEngineProvider);
      await engine.warmUp();
      final pcm = await _sttRecorder.recordPcmClip(
        duration: const Duration(seconds: 3),
      );
      if (!mounted) return;
      setState(() {
        _sttStatus = 'transcribing ${pcm.length} bytes of PCM...';
      });
      final result = await engine.transcribe(pcm);
      if (!mounted) return;
      setState(() {
        if (result.text.trim().isNotEmpty) {
          _sosDescription = result.text.trim();
        }
        _sttStatus =
            'STT ok · "${result.text}" · '
            'conf ${result.confidence.toStringAsFixed(2)} · '
            '${result.modelId}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _sttStatus = 'STT failed: $error');
    } finally {
      if (mounted) setState(() => _sttTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gatewayEnabledProvider, (_, _) => _applyGatewaySettings());
    ref.listen(gatewayUrlProvider, (_, _) => _applyGatewaySettings());
    ref.listen(gatewayDemoKeyProvider, (_, _) => _applyGatewaySettings());
    return EmergencyHomeScreen(
      eventModeActive: _eventModeActive,
      sending: _sosPacketSending || _sttTesting,
      emergencyType: _selectedEmergencyType,
      description: _sosDescription,
      holdSeconds: ref.watch(sosTimeoutProvider).round(),
      onSos: () => unawaited(_sendSosPacket(_selectedEmergencyType)),
      onProfile: () => unawaited(_openProfile()),
      onEmergencyType: () => unawaited(_chooseEmergencyType()),
      onVoice: () => unawaited(_runSttSmokeTest()),
      onDescribe: () => unawaited(_describeSos()),
      onCreateRoom: () => unawaited(_createEventAndRoom()),
      onJoinRoom: () => unawaited(_joinRoomScanQr()),
    );
  }
}

/// Owns its own [TextEditingController] lifecycle so Flutter disposes it
/// when this sheet's element unmounts, rather than the caller disposing it
/// immediately after popping (which can race with the sheet's closing
/// animation and trip the 'framework.dart' `_dependents.isEmpty` assertion).
class _DescribeSosSheet extends StatefulWidget {
  const _DescribeSosSheet({required this.initialText});

  final String initialText;

  @override
  State<_DescribeSosSheet> createState() => _DescribeSosSheetState();
}

class _DescribeSosSheetState extends State<_DescribeSosSheet> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Describe the emergency',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add what happened, where you are, and any immediate danger.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 4,
            maxLines: 7,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Type emergency details',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('Save details'),
          ),
        ],
      ),
    ),
  );
}

class _SosTypeSelectionScreen extends StatelessWidget {
  const _SosTypeSelectionScreen();

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return MeshPage(
      title: 'Emergency Type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose the type that best describes the emergency. You can still send a general SOS.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: MeshSpace.lg),
          for (final type in SosEmergencyType.values) ...[
            MeshCard(
              onTap: () => Navigator.of(context).pop(type),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.ember.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconFor(type), color: palette.ember),
                  ),
                  const SizedBox(width: MeshSpace.md),
                  Expanded(
                    child: Text(
                      type.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: MeshSpace.sm),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(SosEmergencyType type) => switch (type) {
    SosEmergencyType.general => Icons.sos,
    SosEmergencyType.fire => Icons.local_fire_department,
    SosEmergencyType.crime => Icons.gavel,
    SosEmergencyType.kidnap => Icons.person_search,
    SosEmergencyType.medical => Icons.medical_services,
    SosEmergencyType.naturalDisaster => Icons.tsunami,
  };
}

class _SosCountdownDialog extends StatefulWidget {
  const _SosCountdownDialog();

  @override
  State<_SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<_SosCountdownDialog> {
  Timer? _timer;
  var _secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Icon(
      Icons.warning_amber_rounded,
      color: MeshPalette.of(context).ember,
    ),
    title: const Text('Send emergency SOS?'),
    content: Text(
      'Your identity-bound SOS packet will send in $_secondsRemaining '
      '${_secondsRemaining == 1 ? 'second' : 'seconds'}.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
    ],
  );
}
