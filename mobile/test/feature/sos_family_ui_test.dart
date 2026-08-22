import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/sos_delivery.dart';
import 'package:meshsetu_mobile/core/ble/sos_advertisement.dart';
import 'package:meshsetu_mobile/feature/sos/compact_sos_packet_screen.dart';
import 'package:meshsetu_mobile/feature/sos/emergency_active_screen.dart';
import 'package:meshsetu_mobile/ui/components/mesh_components.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: MeshTheme.light(), home: child);

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
    testWidgets('shows mesh-connected step when mesh is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const EmergencyActiveScreen(
            locationStatus: 'GPS captured',
            meshActive: true,
          ),
        ),
      );

      expect(find.text('Emergency mesh connected'), findsOneWidget);
      expect(find.text('GPS captured'), findsOneWidget);
      expect(find.text('Queued for emergency mesh'), findsNothing);
    });

    testWidgets('shows queued step and incomplete location when unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const EmergencyActiveScreen(
            locationStatus: 'Location unavailable',
            meshActive: false,
          ),
        ),
      );

      expect(find.text('Queued for emergency mesh'), findsOneWidget);
      final steps = tester.widgetList<MeshEmergencyStep>(
        find.byType(MeshEmergencyStep),
      );
      final locationStep = steps.firstWhere(
        (step) => step.title == 'Location attached',
      );
      expect(locationStep.complete, isFalse);
    });

    testWidgets('does not claim delivery before a peer acknowledgement', (
      tester,
    ) async {
      final tracker = SosDeliveryTracker(
        const SosDeliveryStatus(
          eventId: 'event-1',
          objectId: 41,
          phase: SosDeliveryPhase.queued,
          locationStatus: 'GPS captured',
        ),
      );
      addTearDown(tracker.dispose);
      await tester.pumpWidget(
        _wrap(
          EmergencyActiveScreen(
            locationStatus: 'GPS captured',
            meshActive: true,
            delivery: tracker,
          ),
        ),
      );

      expect(find.text('SOS saved · mesh relay pending'), findsOneWidget);
      expect(find.text('Emergency mesh delivery confirmed'), findsNothing);
      expect(
        tester
            .widgetList<MeshEmergencyStep>(find.byType(MeshEmergencyStep))
            .firstWhere((step) => step.title == 'Queued for emergency mesh')
            .complete,
        isFalse,
      );

      tracker.apply(
        const SosDeliveryEvent(
          kind: SosDeliveryEventKind.relayConfirmed,
          objectId: 41,
          eventId: 'event-1',
          peerId: 'receiver-1',
        ),
      );
      await tester.pump();

      expect(find.text('Emergency mesh delivery confirmed'), findsNWidgets(2));
      expect(find.text('SOS saved · mesh relay pending'), findsNothing);
    });

    testWidgets(
      'shows broadcast degradation without claiming remote delivery',
      (tester) async {
        final tracker = SosDeliveryTracker(
          const SosDeliveryStatus(
            eventId: 'event-2',
            objectId: 42,
            phase: SosDeliveryPhase.queued,
            locationStatus: 'Location unavailable',
          ),
        );
        addTearDown(tracker.dispose);
        tracker.apply(
          const SosDeliveryEvent(
            kind: SosDeliveryEventKind.broadcastFailed,
            objectId: 42,
            detail: 'BLE advertiser rejected the campaign',
          ),
        );
        await tester.pumpWidget(
          _wrap(
            EmergencyActiveScreen(
              locationStatus: 'Location unavailable',
              meshActive: true,
              delivery: tracker,
            ),
          ),
        );

        expect(find.text('SOS saved · mesh relay pending'), findsOneWidget);
        expect(
          find.textContaining('Compact BLE broadcast unavailable'),
          findsOneWidget,
        );
        expect(find.text('Emergency mesh delivery confirmed'), findsNothing);
      },
    );

    testWidgets('return to home pops the screen', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EmergencyActiveScreen(
                      locationStatus: 'GPS captured',
                      meshActive: true,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Active'), findsWidgets);

      await tester.tap(find.text('Return to home'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Active'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
