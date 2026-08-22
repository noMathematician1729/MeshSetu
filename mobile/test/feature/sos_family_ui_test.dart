import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/ble/sos_advertisement.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/sos/compact_sos_packet_screen.dart';
import 'package:meshsetu_mobile/feature/sos/emergency_active_screen.dart';
import 'package:meshsetu_mobile/ui/components/mesh_components.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: MeshTheme.light(), home: child),
    );

void main() {
  group('CompactSosPacketScreen', () {
    testWidgets('renders sender, packet, and relay facts via MeshDataRow', (
      tester,
    ) async {
      const alert = MeshSosAdvertisement(
        siteFingerprint: 1,
        originId: 0xDEADBEEF,
        sequence: 42,
        flags: MeshSosAdvertisement.alertFlag,
        ttl: 3,
      );
      await tester.pumpWidget(
        _wrap(const CompactSosPacketScreen(alert: alert)),
      );

      expect(find.text('SOS Packet'), findsOneWidget);
      expect(find.byType(MeshDataRow), findsNWidgets(3));
      expect(find.text('3 hops remaining'), findsOneWidget);
      expect(find.text('Anonymous mesh sender'), findsOneWidget);
    });

    testWidgets('shows the CEAL identity when a reporter UID is present', (
      tester,
    ) async {
      const alert = MeshSosAdvertisement(
        siteFingerprint: 1,
        originId: 2,
        sequence: 1,
        flags: MeshSosAdvertisement.alertFlag,
        ttl: 1,
        reporterUidHex: 'abcd12345678',
      );
      await tester.pumpWidget(
        _wrap(const CompactSosPacketScreen(alert: alert)),
      );

      expect(find.textContaining('CEAL ID'), findsOneWidget);
      expect(find.text('1 hop remaining'), findsOneWidget);
    });
  });

  group('EmergencyActiveScreen', () {
    testWidgets('shows the scanning radar and location panel', (tester) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _wrap(
          const EmergencyActiveScreen(
            locationStatus: 'GPS captured',
            meshActive: true,
          ),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();

      expect(find.text('Emergency Active'), findsWidgets);
      expect(
        find.textContaining('Scanning for nearby devices'),
        findsOneWidget,
      );
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('GPS captured'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Drift schedules a zero-duration internal timer when a StreamBuilder's
      // query stream is cancelled at teardown; give it one more pump cycle so
      // flutter_test's strict `!timersPending` check doesn't fire against it.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('shows scanning inactive when mesh is not active', (
      tester,
    ) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _wrap(
          const EmergencyActiveScreen(
            locationStatus: 'Location unavailable',
            meshActive: false,
          ),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();

      expect(find.text('Mesh scanning is not active'), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('renders a delivery panel when an eventId is provided', (
      tester,
    ) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.outboxEvents)
          .insert(
            OutboxEventsCompanion.insert(
              eventId: 'evt-1',
              siteId: 'site',
              roomId: 'public',
              payloadType: 'structuredSos',
              priority: 'p0Critical',
              state: const Value('acked'),
              createdAtMs: now,
              updatedAtMs: now,
              expiresAtMs: now + 60000,
            ),
          );
      await tester.pumpWidget(
        _wrap(
          const EmergencyActiveScreen(
            eventId: 'evt-1',
            locationStatus: 'GPS captured',
            meshActive: true,
          ),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Admin delivery pending'), findsOneWidget);
      // The radar sweep runs a repeating AnimationController, and Drift
      // schedules a zero-duration internal timer when the delivery
      // StreamBuilder's query stream is cancelled — settle both before the
      // test ends so flutter_test's strict `!timersPending` check passes.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('return to home pops the screen', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 1400)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmergencyActiveScreen(
                      locationStatus: 'GPS captured',
                      meshActive: false,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Active'), findsWidgets);

      await tester.dragUntilVisible(
        find.text('Return to home'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('Return to home'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Active'), findsNothing);
      expect(find.text('open'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  });
}
