import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_mode_launcher.dart';
import 'mesh_bridge_client.dart';
import 'providers.dart';

/// Binds a room's joined site to the foreground BLE task and its UI-isolate
/// outbox bridge. This is intentionally shared by the lobby and chat screens:
/// participants may enter either screen without first visiting Event Mode.
abstract final class RoomMeshBootstrap {
  static Future<EventModeLaunchResult> startForSite({
    required WidgetRef ref,
    required String siteId,
    required void Function() taskCallback,
  }) async {
    await EventModeLauncher.initialize();
    final bridge = _ensureBridge(ref);
    bridge.prepareForSite(siteId: siteId);

    final result = await EventModeLauncher.start(
      taskCallback: taskCallback,
      onStatus: bridge.reportBlockedReason,
      onMeshSiteConfigurationNeeded: () =>
          EventModeLauncher.configureMeshSite(siteId),
    );

    if (result == EventModeLaunchResult.alreadyRunning) {
      // EventModeLauncher intentionally does not invoke its configuration
      // callback on this fast path. Configure the already-running task and
      // ask it to return its identity to this newly attached bridge.
      await EventModeLauncher.configureMeshSite(siteId);
      _requestIdentityWithRetry(bridge);
    } else if (result == EventModeLaunchResult.started) {
      // The service request can complete before its task isolate has created
      // the controller. Replay the identity request after startup as a
      // safeguard for the first-start callback race.
      _requestIdentityWithRetry(bridge);
    }
    return result;
  }

  /// Binds the UI-isolate outbox bridge to [siteId] **without** starting the
  /// foreground service or triggering any permission prompt.
  ///
  /// Room screens call this on open. Without it the durable outbox is never
  /// constructed for the room's site, so an offline-composed message is
  /// written to `outboxEvents` as `ready` and then sits there forever: the
  /// live internet socket is wired up independently in the screen's
  /// `initState`, which is why room chat appeared to work online but never
  /// delivered offline. When Event Mode is already running (started from Home
  /// or a previous session) this also re-requests the task identity so the
  /// outbox activates immediately instead of waiting for the user to press
  /// "Start event mode" inside the room.
  static Future<void> attachForSite({
    required WidgetRef ref,
    required String siteId,
  }) async {
    final bridge = _ensureBridge(ref);
    bridge.prepareForSite(siteId: siteId);
    bool running;
    try {
      running = await FlutterForegroundTask.isRunningService;
    } catch (_) {
      // Plugin unavailable (unit tests / unsupported platform). Preparing the
      // bridge above is still the useful half of this call.
      return;
    }
    if (!running) return;
    // The already-running task may have been configured for a different site.
    await EventModeLauncher.configureMeshSite(siteId);
    _requestIdentityWithRetry(bridge);
  }

  static void _requestIdentityWithRetry(MeshBridgeClient bridge) {
    unawaited(() async {
      for (final delay in const [
        Duration.zero,
        Duration(milliseconds: 500),
        Duration(seconds: 2),
      ]) {
        if (delay > Duration.zero) await Future<void>.delayed(delay);
        bridge.requestForegroundIdentity();
      }
    }());
  }

  static MeshBridgeClient _ensureBridge(WidgetRef ref) {
    final existing = ref.read(meshBridgeClientProvider);
    if (existing != null) return existing;
    final bridge = MeshBridgeClient(ref.read(databaseProvider));
    ref.read(meshBridgeClientProvider.notifier).state = bridge;
    return bridge;
  }
}
