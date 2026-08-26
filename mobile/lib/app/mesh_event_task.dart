// ignore_for_file: unused_element, unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/ble/device_key_store.dart';
import '../core/ble/mesh_gatt.dart';
import '../core/ble/sos_advertisement.dart';
import '../core/model/model.dart';
import '../feature/sos/sos_payload.dart';
import 'event_mode_launcher.dart';
import 'mesh_bridge.dart';
import 'mesh_event_controller.dart';
import 'notification_router.dart';
import 'room_message_notifications.dart';
import 'sos_alert_notifications.dart';
import 'sos_incident_navigator.dart';

/// Foreground task handler for `in.meshsetu.app.MeshEventService`'s Flutter
/// port. Extracted out of `event_mode_screen.dart` (Task 3 of the UI
/// revamp) — this file is pure mesh/notification logic, running in its own
/// isolate, and imports no UI. It is a straight move with no behavior
/// change; see `EventModeScreen` in `event_mode_screen.dart` for the UI
/// half that used to live alongside it.
const String _sosNotificationChannelId = 'meshsetu-sos-alerts-v1';
final FlutterLocalNotificationsPlugin _sosNotifications =
    FlutterLocalNotificationsPlugin();
bool _sosNotificationsInitialized = false;

Future<void> _showSosNotification({
  required ReceivedObject received,
  required String detail,
  int? notificationId,
}) async {
  try {
    if (!_sosNotificationsInitialized) {
      await NotificationRouter.configure(_sosNotifications);
      _sosNotificationsInitialized = true;
    }
    var id = notificationId ?? (received.envelope.objectId & 0x7fffffff);
    if (id == 0) id = 1;
    await _sosNotifications.show(
      id: id,
      title: 'SOS RECEIVED',
      body: detail,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _sosNotificationChannelId,
          'SOS alerts',
          channelDescription: 'Nearby MeshSetu emergency signals',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          ticker: 'SOS received',
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          onlyAlertOnce: true,
        ),
      ),
      payload: NotificationRouter.incidentPayload(
        siteId: received.envelope.siteId,
        eventId: received.envelope.eventId,
        objectId: received.envelope.objectId,
      ),
    );
  } catch (_) {
    // A notification failure must not stop BLE relaying.
  }
}

Future<void> _showCompactSosNotification(MeshSosAdvertisement alert) async {
  final shown = await SosAlertNotifications.show(
    id: SosAlertNotifications.idForKey(alert.dedupeKey),
    title: alert.isTest ? 'TEST SOS RECEIVED' : 'SOS RECEIVED · MESH',
    body: alert.isTest
        ? 'Nearby BLE transport test received.'
        : SosAlertNotifications.compactPacketBody(
            alert,
            availability:
                'Offline-ready: attempting verified detail lookup when available.',
          ),
    payload: alert.isTest
        ? null
        : SosIncidentNavigator.payloadForCompactAlert(alert),
  );
  if (!shown) {
    FlutterForegroundTask.sendDataToMain({
      'status': 'compact_sos_notification_failed',
      'dedupeKey': alert.dedupeKey,
      'message':
          'SOS received over Bluetooth, but Android did not display the notification. Check Notifications permission and channel settings.',
    });
  }
}

/// Port of `in.meshsetu.app.MeshEventService`'s foreground service. The mesh
/// controller is deliberately created in this task isolate, not the UI one.
@pragma('vm:entry-point')
void meshEventTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_MeshEventTaskHandler());
}

class _MeshEventTaskHandler extends TaskHandler {
  MeshEventController? _controller;
  bool _sosPending = false;
  bool _identityRequestPending = false;
  bool _debugLossEnabled = false;
  StreamSubscription<ReceivedObject>? _incomingSubscription;
  int _notificationGeneration = 0;
  final Set<String> _compactAlertKeys = {};

  /// RoomId of the room chat screen currently visible to the user, or null.
  /// Set via the 'active_room' message from the room chat screen. When
  /// non-null, notifications for that room are suppressed (Task 5).
  String? _activeRoomId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    try {
      final savedConfiguration = await FlutterForegroundTask.getData<String>(
        key: meshSiteConfigurationKey,
      );
      final configuration = savedConfiguration == null
          ? MeshSiteConfiguration.demo
          : MeshSiteConfiguration.decode(savedConfiguration) ??
                MeshSiteConfiguration.demo;
      final controller = MeshEventController(
        configuration: configuration,
        zoneResolver: MeshEventController.demoZoneResolver,
        onPeerState: (peers) => FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_peers',
          'peers': [
            for (final peer in peers)
              {
                'peerId': peer.peerId,
                'connected': peer.connected,
                'mtu': peer.mtu,
                'rssi': peer.rssi,
                'queuedObjects': peer.queuedObjects,
                'lastSeenMs': peer.lastSeenMs,
              },
          ],
        }),
        onMeshStatus: (status) => FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_status',
          'value': status,
        }),
        onMetrics: (metrics) => FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_metric',
          'metrics': [
            for (final metric in metrics)
              {
                'kind': metric.kind,
                'peerId': metric.peerId,
                'value': metric.value,
                'objectId': metric.objectId,
                'detail': metric.detail,
              },
          ],
        }),
        onBeaconObservations: (observations) =>
            FlutterForegroundTask.sendDataToMain({
              'status': 'mesh_beacons',
              'beacons': [
                for (final beacon in observations)
                  {
                    'anchorId': beacon.anchorId,
                    'rssi': beacon.rssi,
                    'observedAtMs': beacon.observedAtMs,
                  },
              ],
            }),
        onZoneEstimate: (estimate) => FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_zone',
          'zone': estimate.logicalZone,
          'anchorId': estimate.anchorId,
          'uncertainty': estimate.uncertainty,
        }),
        onCompactSosAlert: _announceCompactSos,
      );
      await controller.start();
      _controller = controller;
      _incomingSubscription = controller.coordinator?.incoming.listen((
        received,
      ) {
        FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_metric',
          'metrics': [
            {
              'kind': 'object_received',
              'peerId': received.peerId,
              'value': received.envelope.payload.length,
              'objectId': received.envelope.objectId,
            },
          ],
        });
        FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_received',
          'received': MeshBridge.receivedToJson(received),
        });
        if (received.envelope.payloadType == PayloadType.structuredSos) {
          unawaited(_announceReceivedSos(received));
        } else if (received.envelope.payloadType == PayloadType.roomMessage) {
          unawaited(_announceReceivedRoomMessage(received));
        }
      });
      controller.setDebugLossInjection(_debugLossEnabled);
      FlutterForegroundTask.sendDataToMain({
        'status': 'started',
        'localEphemeralId': controller.localEphemeralId,
      });
      if (_identityRequestPending) {
        _identityRequestPending = false;
        FlutterForegroundTask.sendDataToMain({
          'status': 'started',
          'localEphemeralId': controller.localEphemeralId,
        });
      }
      if (_sosPending) {
        _sosPending = false;
        unawaited(_sendTestSos(controller));
      }
    } catch (error) {
      final message = error is DeviceKeyStoreException
          ? error.userMessage
          : error.toString();
      FlutterForegroundTask.sendDataToMain({
        'status': 'error',
        'message': message,
      });
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;
    await _controller?.stop();
    _controller = null;
    FlutterForegroundTask.sendDataToMain(const {'status': 'stopped'});
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map && data['meshSiteConfiguration'] is String) {
      final configuration = MeshSiteConfiguration.decode(
        data['meshSiteConfiguration'] as String,
      );
      if (configuration != null &&
          configuration.siteId != _controller?.configuration.siteId) {
        unawaited(_restartForSite(configuration));
      }
      return;
    }
    if (data is Map && data['mesh_identity_request'] == true) {
      final controller = _controller;
      if (controller == null) {
        _identityRequestPending = true;
      } else {
        FlutterForegroundTask.sendDataToMain({
          'status': 'started',
          'localEphemeralId': controller.localEphemeralId,
        });
      }
      return;
    }
    if (data is Map && data.containsKey('active_room')) {
      // null means the user left the room screen; a non-null string means they
      // are viewing that room. Notifications for the active room are suppressed.
      final value = data['active_room'];
      _activeRoomId = value is String && value.isNotEmpty ? value : null;
      return;
    }
    if (data is Map && data['debugLoss'] is bool) {
      _debugLossEnabled = data['debugLoss'] as bool;
      _controller?.setDebugLossInjection(_debugLossEnabled);
      return;
    }
    if (data is Map && data['sendMeshObject'] is Map) {
      final envelope = MeshBridge.envelopeFromJson(
        (data['sendMeshObject'] as Map).cast<Object?, Object?>(),
      );
      unawaited(_submitMeshObject(envelope));
      return;
    }
    if (data is Map && data['broadcast_ceal_sos'] == true) {
      final originId = data['originId'] as int?;
      final reporterUid = data['reporterUid'] as String?;
      final flags = data['flags'] as int? ?? MeshSosAdvertisement.alertFlag;
      final controller = _controller;
      if (controller != null) {
        unawaited(
          controller.broadcastCompactSos(
            isTest: false,
            originId: originId,
            reporterUidHex: reporterUid,
            emergencyType: SosEmergencyType.fromFlags(flags),
          ),
        );
        FlutterForegroundTask.sendDataToMain(const {
          'status': 'ceal_sos_broadcast_ok',
        });
      } else {
        FlutterForegroundTask.sendDataToMain(const {
          'status': 'sos_failed',
          'message': 'event mode not ready',
        });
      }
      return;
    }
    if (data != 'send_test_sos') return;
    final controller = _controller;
    if (controller == null) {
      _sosPending = true;
    } else {
      unawaited(_sendTestSos(controller));
    }
  }

  Future<void> _restartForSite(MeshSiteConfiguration configuration) async {
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;
    await _controller?.stop();
    _controller = null;
    await FlutterForegroundTask.saveData(
      key: meshSiteConfigurationKey,
      value: configuration.encode(),
    );
    await onStart(DateTime.now(), TaskStarter.developer);
  }

  Future<void> _sendTestSos(MeshEventController controller) async {
    try {
      final envelope = await controller.sendTestObject();
      if (envelope == null) {
        FlutterForegroundTask.sendDataToMain(const {'status': 'sos_failed'});
      } else {
        FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_test_origin_submitted',
          'envelope': MeshBridge.envelopeToJson(envelope),
        });
      }
    } catch (error) {
      FlutterForegroundTask.sendDataToMain({
        'status': 'sos_failed',
        'message': error.toString(),
      });
    }
  }

  Future<void> _submitMeshObject(MeshEnvelope envelope) async {
    final controller = _controller;
    if (controller == null || controller.coordinator == null) {
      FlutterForegroundTask.sendDataToMain({
        'status': 'mesh_submit_result',
        'objectId': envelope.objectId,
        'eventId': envelope.eventId,
        'accepted': false,
        'reason': 'event mode is not ready',
      });
      return;
    }
    try {
      final gatewayPacket = await controller.coordinator!.encryptForGateway(
        envelope,
      );
      if (envelope.payloadType == PayloadType.structuredSos) {
        String reporterUid = '';
        var emergencyType = SosEmergencyType.general;
        try {
          final sos = StructuredSosPayload.decode(envelope.payload);
          reporterUid = sos.reporter?.reporterUid ?? '';
          emergencyType = SosEmergencyType.fromHazards(sos.hazards);
        } catch (_) {
          // A non-identity structured payload still broadcasts a routing alert.
        }
        unawaited(
          controller.broadcastCompactSos(
            originId: envelope.originEphemeralId,
            sequence: envelope.objectId & 0xffff,
            reporterUidHex: reporterUid,
            emergencyType: emergencyType,
            objectId: envelope.objectId,
          ),
        );
      }
      await controller.coordinator!.send(envelope);
      FlutterForegroundTask.sendDataToMain({
        'status': 'mesh_submit_result',
        'objectId': envelope.objectId,
        'eventId': envelope.eventId,
        'accepted': true,
      });
      if (envelope.payloadType == PayloadType.structuredSos ||
          envelope.payloadType == PayloadType.voiceObject) {
        FlutterForegroundTask.sendDataToMain({
          'status': 'mesh_origin_submitted',
          'envelope': MeshBridge.envelopeToJson(envelope),
          'encryptedBytes': base64Encode(gatewayPacket.bytes),
        });
      }
    } catch (error) {
      FlutterForegroundTask.sendDataToMain({
        'status': 'mesh_submit_result',
        'objectId': envelope.objectId,
        'eventId': envelope.eventId,
        'accepted': false,
        'reason': '$error',
      });
    }
  }

  Future<void> _announceReceivedRoomMessage(ReceivedObject received) async {
    final alert = roomMessageAlertFor(
      received: received,
      localEphemeralId: _controller?.localEphemeralId,
      activeRoomId: _activeRoomId,
    );
    if (alert == null) return;
    await RoomMessageNotifications.show(
      alert: alert,
      payload: RoomMessageNotifications.roomPayload(
        siteId: alert.siteId,
        roomId: alert.roomId,
      ),
    );
  }

  void _announceCompactSos(MeshSosAdvertisement alert) {
    // BLE advertisements repeat. A single compact packet must produce one
    // notification and one control-room lookup for this Event Mode session.
    if (!_compactAlertKeys.add(alert.dedupeKey)) return;
    unawaited(_showCompactSosNotification(alert));
    // Forward to the UI isolate so MeshBridgeClient can relay to admin backend.
    if (!alert.isTest) {
      FlutterForegroundTask.sendDataToMain({
        'status': 'compact_sos_received',
        'originId': alert.originId,
        'sequence': alert.sequence,
        'flags': alert.flags,
        'ttl': alert.ttl,
        'siteFingerprint': alert.siteFingerprint,
        'dedupeKey': alert.dedupeKey,
        'reporterUid': alert.reporterUidHex,
      });
    }
  }

  Future<void> _announceReceivedSos(ReceivedObject received) async {
    final generation = ++_notificationGeneration;
    late final String detail;
    try {
      final sos = StructuredSosPayload.decode(received.envelope.payload);
      final location = sos.latitude == null || sos.longitude == null
          ? 'location unavailable'
          : 'GPS ${sos.latitude!.toStringAsFixed(5)}, '
                '${sos.longitude!.toStringAsFixed(5)}';
      final reporter = sos.reporter?.name;
      detail = reporter != null && reporter.isNotEmpty
          ? 'From $reporter · ${sos.triagePriority.name} · $location'
          : 'Priority ${sos.triagePriority.name} · $location';
    } catch (_) {
      // A random/test structured frame is not an SOS notification.
      return;
    }
    final compactKey =
        '${MeshGatt.siteFingerprint(received.envelope.siteId, namespace: MeshSiteConfiguration.forSite(received.envelope.siteId).namespace) & 0xffffffff}:${received.envelope.originEphemeralId & 0xffffffff}:${received.envelope.objectId & 0xffff}';
    final updatesCompactAlert = _compactAlertKeys.contains(compactKey);
    await _showSosNotification(
      received: received,
      detail: detail,
      notificationId: updatesCompactAlert
          ? SosAlertNotifications.idForKey(compactKey)
          : null,
    );
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'SOS RECEIVED',
        notificationText: detail,
      );
    } catch (_) {
      // The separate SOS notification above remains the user-visible alert.
    }
    await Future<void>.delayed(const Duration(seconds: 6));
    if (generation != _notificationGeneration) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'MeshSetu event mode active',
        notificationText: 'BLE relay is listening for nearby peers',
      );
    } catch (_) {}
  }
}
