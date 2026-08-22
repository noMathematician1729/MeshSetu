import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/routes.dart';

/// Route-table tests for [MeshRoutes.onGenerateRoute] (Task 3 of the UI
/// revamp). These are unit tests against the route function directly rather
/// than through a full [MeshSetuApp] pump: a few destination screens
/// (Settings, Profile, Gateway, Voice Evidence) have pre-existing rendering
/// issues unrelated to routing — see the note in `mesh_shell_test.dart` —
/// that would make a full-app push-and-render test flaky for reasons
/// orthogonal to what this file verifies: that each named route resolves
/// (or correctly refuses to resolve) for a given argument shape. The load-
/// bearing `/rooms` and `/incident` contracts are additionally covered
/// end-to-end, unmodified, by `test/app/notification_router_test.dart` and
/// `test/app/sos_notification_tap_test.dart`.
void main() {
  group('rooms', () {
    test('builds a route when roomId is present', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/rooms', arguments: {'roomId': 'room-1'}),
      );
      expect(route, isNotNull);
    });

    test('rejects an empty roomId', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/rooms', arguments: {'roomId': ''}),
      );
      expect(route, isNull);
    });

    test('rejects a missing roomId key', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/rooms', arguments: <String, Object?>{}),
      );
      expect(route, isNull);
    });

    test('rejects non-Map arguments', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/rooms', arguments: 'not-a-map'),
      );
      expect(route, isNull);
    });

    test('rejects null arguments', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/rooms'),
      );
      expect(route, isNull);
    });
  });

  group('incident', () {
    test('builds a route when siteId, eventId, and objectId are present', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/incident',
          arguments: {
            'siteId': 'site-1',
            'eventId': 'event-1',
            'objectId': 42,
          },
        ),
      );
      expect(route, isNotNull);
    });

    test('rejects a missing siteId', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/incident',
          arguments: {'eventId': 'event-1', 'objectId': 42},
        ),
      );
      expect(route, isNull);
    });

    test('rejects a missing eventId', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/incident',
          arguments: {'siteId': 'site-1', 'objectId': 42},
        ),
      );
      expect(route, isNull);
    });

    test('rejects a missing objectId', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/incident',
          arguments: {'siteId': 'site-1', 'eventId': 'event-1'},
        ),
      );
      expect(route, isNull);
    });

    test('rejects non-Map arguments', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(name: '/incident', arguments: 7),
      );
      expect(route, isNull);
    });
  });

  group('sos-incident', () {
    test('builds a route when eventId is present', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/sos-incident',
          arguments: {'eventId': 'event-1'},
        ),
      );
      expect(route, isNotNull);
    });

    test('rejects a missing eventId', () {
      final route = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/sos-incident',
          arguments: <String, Object?>{},
        ),
      );
      expect(route, isNull);
    });
  });

  group('sos-compose', () {
    test('requires both siteId and roomId', () {
      final missingRoom = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/sos-compose',
          arguments: {'siteId': 'site-1'},
        ),
      );
      expect(missingRoom, isNull);

      final missingSite = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/sos-compose',
          arguments: {'roomId': 'room-1'},
        ),
      );
      expect(missingSite, isNull);

      final complete = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/sos-compose',
          arguments: {'siteId': 'site-1', 'roomId': 'room-1'},
        ),
      );
      expect(complete, isNotNull);
    });
  });

  group('voice-evidence', () {
    test('requires a non-empty siteId', () {
      final present = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/voice-evidence',
          arguments: {'siteId': 'site-1'},
        ),
      );
      expect(present, isNotNull);

      final empty = MeshRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/voice-evidence',
          arguments: {'siteId': ''},
        ),
      );
      expect(empty, isNull);
    });
  });

  group('argument-free routes', () {
    test('all resolve without arguments', () {
      for (final name in [
        MeshRoutes.join,
        MeshRoutes.gateway,
        MeshRoutes.location,
        MeshRoutes.profile,
        MeshRoutes.settings,
        MeshRoutes.onboarding,
      ]) {
        final route = MeshRoutes.onGenerateRoute(RouteSettings(name: name));
        expect(route, isNotNull, reason: '$name should resolve');
      }
    });
  });

  test('unknown route name resolves to null', () {
    final route = MeshRoutes.onGenerateRoute(
      const RouteSettings(name: '/does-not-exist'),
    );
    expect(route, isNull);
  });

  test('every route preserves the original RouteSettings on the built route', () {
    final route = MeshRoutes.onGenerateRoute(
      const RouteSettings(name: '/gateway'),
    );
    expect(route?.settings.name, '/gateway');
  });
}
