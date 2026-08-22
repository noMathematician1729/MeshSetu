import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/core/ble/sos_advertisement.dart';
import 'package:meshsetu_mobile/feature/home/emergency_home_screen.dart';
import 'package:meshsetu_mobile/ui/components/mesh_components.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

void main() {
  testWidgets('emergency home preserves the reference hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: EmergencyHomeScreen(
          eventModeActive: true,
          sending: false,
          emergencyType: SosEmergencyType.medical,
          description: 'Need medical help',
          holdSeconds: 3,
          onSos: () {},
          onProfile: () {},
          onEmergencyType: () {},
          onVoice: () {},
          onDescribe: () {},
          onCreateRoom: () {},
          onJoinRoom: () {},
        ),
      ),
    );

    expect(find.text('Emergency Aid'), findsOneWidget);
    expect(find.byType(MeshSosButton), findsOneWidget);
    // Task 4: emergency type now surfaces in both the status rail and the
    // action tile subtitle, so this appears twice rather than once.
    expect(find.textContaining('Medical'), findsWidgets);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('shows mesh status and hold-time in the status rail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: EmergencyHomeScreen(
          eventModeActive: true,
          sending: false,
          emergencyType: SosEmergencyType.general,
          description: '',
          holdSeconds: 4,
          onSos: () {},
          onProfile: () {},
          onEmergencyType: () {},
          onVoice: () {},
          onDescribe: () {},
          onCreateRoom: () {},
          onJoinRoom: () {},
        ),
      ),
    );

    expect(find.byType(MeshStatRail), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('4s'), findsOneWidget);
  });

  testWidgets('offline (event mode inactive) shows Offline in the rail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: EmergencyHomeScreen(
          eventModeActive: false,
          sending: false,
          emergencyType: SosEmergencyType.general,
          description: '',
          holdSeconds: 3,
          onSos: () {},
          onProfile: () {},
          onEmergencyType: () {},
          onVoice: () {},
          onDescribe: () {},
          onCreateRoom: () {},
          onJoinRoom: () {},
        ),
      ),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
  });

  testWidgets('sending state switches the hero to the live ember accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: EmergencyHomeScreen(
          eventModeActive: true,
          sending: true,
          emergencyType: SosEmergencyType.general,
          description: '',
          holdSeconds: 3,
          onSos: () {},
          onProfile: () {},
          onEmergencyType: () {},
          onVoice: () {},
          onDescribe: () {},
          onCreateRoom: () {},
          onJoinRoom: () {},
        ),
      ),
    );

    final hero = tester.widget<MeshHeroSurface>(find.byType(MeshHeroSurface));
    expect(hero.live, isTrue);
    expect(
      find.text('Preparing your encrypted emergency packet…'),
      findsOneWidget,
    );
    // Sending disables the SOS button so a second packet can't be queued
    // mid-send.
    final sos = tester.widget<MeshSosButton>(find.byType(MeshSosButton));
    expect(sos.enabled, isFalse);
  });

  testWidgets('SOS activates only after the configured hold', (tester) async {
    var activated = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: Scaffold(
          body: Center(
            child: MeshSosButton(
              holdDuration: const Duration(seconds: 2),
              onActivated: () => activated++,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MeshSosButton)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(activated, 0);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(activated, 1);
    await gesture.up();
  });
}
