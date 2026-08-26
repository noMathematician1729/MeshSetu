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
    // Emergency type is shown only in its dedicated action tile.
    expect(find.textContaining('Medical'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('shows a start event mode control when event mode is inactive', (
    tester,
  ) async {
    var toggled = 0;
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
          onToggleEventMode: () => toggled++,
        ),
      ),
    );

    expect(find.byTooltip('Start event mode'), findsOneWidget);
    expect(find.byTooltip('Stop event mode'), findsNothing);
    await tester.tap(find.byTooltip('Start event mode'));
    expect(toggled, 1);
  });

  testWidgets('shows a stop event mode control when event mode is active', (
    tester,
  ) async {
    var toggled = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MeshTheme.light(),
        home: EmergencyHomeScreen(
          eventModeActive: true,
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
          onToggleEventMode: () => toggled++,
        ),
      ),
    );

    expect(find.byTooltip('Stop event mode'), findsOneWidget);
    expect(find.byTooltip('Start event mode'), findsNothing);
    await tester.tap(find.byTooltip('Stop event mode'));
    expect(toggled, 1);
  });

  testWidgets(
    'omits the event mode control entirely when no callback is provided',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: EmergencyHomeScreen(
            eventModeActive: true,
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

      expect(find.byTooltip('Stop event mode'), findsNothing);
      expect(find.byTooltip('Start event mode'), findsNothing);
    },
  );

  testWidgets(
    'shows the verified control-room message on the emergency screen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: EmergencyHomeScreen(
            eventModeActive: true,
            sending: false,
            emergencyType: SosEmergencyType.general,
            description: '',
            holdSeconds: 3,
            authorityResponseType: 'SOS_RECEIVED',
            authorityResponseMessage: 'Control room received your SOS.',
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

      expect(find.text('Control room response'), findsOneWidget);
      expect(find.text('SOS_RECEIVED'), findsOneWidget);
      expect(find.text('Control room received your SOS.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a plain-language rejection reason when the response could not be verified',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: EmergencyHomeScreen(
            eventModeActive: true,
            sending: false,
            emergencyType: SosEmergencyType.general,
            description: '',
            holdSeconds: 3,
            authorityRejectionMessage:
                'No active event on this phone. Rejoin or recreate the '
                'event to receive control room responses.',
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

      expect(find.text('Control room response'), findsOneWidget);
      expect(find.text('Could not be verified'), findsOneWidget);
      expect(
        find.text(
          'No active event on this phone. Rejoin or recreate the '
          'event to receive control room responses.',
        ),
        findsOneWidget,
      );
      // Never present alongside the accepted-response card.
      expect(find.text('Verified response received'), findsNothing);
    },
  );

  testWidgets(
    'omits the control-room card entirely with no acceptance or rejection state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: EmergencyHomeScreen(
            eventModeActive: true,
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

      expect(find.text('Control room response'), findsNothing);
    },
  );

  testWidgets(
    'prefers the accepted-response card when both acceptance and a stale rejection are set',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: EmergencyHomeScreen(
            eventModeActive: true,
            sending: false,
            emergencyType: SosEmergencyType.general,
            description: '',
            holdSeconds: 3,
            authorityResponseType: 'SOS_RECEIVED',
            authorityResponseMessage: 'Control room received your SOS.',
            authorityRejectionMessage: 'stale rejection text',
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

      expect(find.text('Verified response received'), findsOneWidget);
      expect(find.text('Could not be verified'), findsNothing);
      expect(find.text('stale rejection text'), findsNothing);
    },
  );

  testWidgets('does not show the top mesh status, hold-time, or type rail', (
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

    expect(find.byType(MeshStatRail), findsNothing);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Offline'), findsNothing);
    expect(find.text('Hold time'), findsNothing);
    expect(find.text('4s'), findsNothing);
    expect(find.text('Type'), findsNothing);
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
