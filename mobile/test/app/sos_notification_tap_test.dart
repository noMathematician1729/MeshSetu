import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/sos_incident_navigator.dart';
import 'package:meshsetu_mobile/core/ble/sos_advertisement.dart';
import 'package:meshsetu_mobile/feature/sos/compact_sos_packet_screen.dart';
import 'package:meshsetu_mobile/feature/sos/incident_detail_screen.dart';
import 'package:meshsetu_mobile/feature/sos/sos_incident_screen.dart';
import 'package:meshsetu_mobile/main.dart';

Widget _app() => const ProviderScope(
  child: MeshSetuApp(enforcePermissions: false, enforceOnboarding: false),
);

void main() {
  testWidgets('notification payload opens the native SOS detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    SosIncidentNavigator.openPayload(
      SosIncidentNavigator.payloadForEvent('ceal-sender-uid-1'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SosIncidentScreen), findsOneWidget);
    expect(find.text('SOS details'), findsOneWidget);
  });

  testWidgets('received mesh SOS opens the verified local incident screen', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    SosIncidentNavigator.openMeshIncident(
      siteId: 'demo-site',
      eventId: 'mesh-event-1',
      objectId: 42,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(IncidentDetailScreen), findsOneWidget);
    expect(find.text('SOS Incident'), findsOneWidget);
  });

  testWidgets('a tap before the navigator mounts is not dropped', (
    tester,
  ) async {
    // Reproduces a cold start: the payload arrives first, the UI mounts after.
    SosIncidentNavigator.openPayload(
      SosIncidentNavigator.payloadForEvent('ceal-cold-start-1'),
    );

    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SosIncidentScreen), findsOneWidget);
  });

  testWidgets('compact SOS tap opens the packet details available offline', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    const alert = MeshSosAdvertisement(
      siteFingerprint: 1,
      originId: 2,
      sequence: 3,
      flags: MeshSosAdvertisement.alertFlag,
      ttl: 4,
    );

    SosIncidentNavigator.openPayload(
      SosIncidentNavigator.payloadForCompactAlert(alert),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CompactSosPacketScreen), findsOneWidget);
    expect(find.text('SOS Packet'), findsOneWidget);
  });

  testWidgets('a non-MeshSetu payload does not navigate', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    SosIncidentNavigator.openPayload('https://example.com/sos/1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SosIncidentScreen), findsNothing);
  });
}
