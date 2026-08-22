import 'package:flutter/material.dart';

import '../feature/gateway/gateway_screen.dart';
import '../feature/join/join_screen.dart';
import '../feature/location/location_screen.dart';
import '../feature/onboarding/onboarding_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/profile/settings_screen.dart';
import '../feature/rooms/rooms_screen.dart';
import '../feature/sos/incident_detail_screen.dart';
import '../feature/sos/sos_incident_screen.dart';
import '../feature/sos/sos_screen.dart';
import '../feature/voice/voice_inbox_screen.dart';

/// Named-route table for MeshSetu (Task 3 of the UI revamp).
///
/// Two routes here — `/rooms` and `/incident` — are load-bearing: they are
/// the exact contract `notification_router.dart` pushes against from
/// [NotificationRouter.open] when a room-message or legacy SOS notification
/// is tapped (`navigator.pushNamed('/rooms', arguments: data)` and
/// `navigator.pushNamed('/incident', arguments: data)`). Their argument
/// shape and null-safety behavior below is preserved exactly from the
/// previous inline `onGenerateRoute` in `main.dart` — do not change the
/// required keys or the "return null on missing/invalid args" behavior
/// without also updating `test/app/notification_router_test.dart` and
/// `test/app/sos_notification_tap_test.dart`.
///
/// Routes are resolved against the *root* navigator (`MaterialApp
/// .navigatorKey`), not a per-tab navigator, so a notification tap always
/// surfaces its destination on top of the entire [MeshShell] regardless of
/// which tab is active.
abstract final class MeshRoutes {
  static const rooms = '/rooms';
  static const incident = '/incident';
  static const sosIncident = '/sos-incident';
  static const sosCompose = '/sos-compose';
  static const join = '/join';
  static const voiceEvidence = '/voice-evidence';
  static const gateway = '/gateway';
  static const location = '/location';
  static const profile = '/profile';
  static const settings = '/settings';
  static const onboarding = '/onboarding';

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;

    switch (routeSettings.name) {
      case rooms:
        if (args is! Map) return null;
        final data = args.cast<String, Object?>();
        final roomId = data['roomId'] as String?;
        if (roomId == null || roomId.isEmpty) return null;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => RoomsScreen(initialRoomId: roomId),
        );

      case incident:
        if (args is! Map) return null;
        final data = args.cast<String, Object?>();
        final siteId = data['siteId'] as String?;
        final eventId = data['eventId'] as String?;
        final objectId = data['objectId'] as int?;
        if (siteId == null || eventId == null || objectId == null) {
          return null;
        }
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => IncidentDetailScreen(
            siteId: siteId,
            eventId: eventId,
            objectId: objectId,
          ),
        );

      case sosIncident:
        if (args is! Map) return null;
        final eventId = args['eventId'] as String?;
        if (eventId == null || eventId.isEmpty) return null;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => SosIncidentScreen(eventId: eventId),
        );

      case sosCompose:
        if (args is! Map) return null;
        final siteId = args['siteId'] as String?;
        final roomId = args['roomId'] as String?;
        if (siteId == null || roomId == null) return null;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => SosScreen(siteId: siteId, roomId: roomId),
        );

      case join:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const JoinScreen(),
        );

      case voiceEvidence:
        if (args is! Map) return null;
        final siteId = args['siteId'] as String?;
        if (siteId == null || siteId.isEmpty) return null;
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => VoiceInboxScreen(siteId: siteId),
        );

      case gateway:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const GatewayScreen(),
        );

      case location:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const LocationScreen(),
        );

      case profile:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const ProfileScreen(),
        );

      case settings:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const SettingsScreen(),
        );

      case onboarding:
        return MaterialPageRoute(
          settings: routeSettings,
          builder: (_) => const OnboardingScreen(),
        );
    }
    return null;
  }
}
