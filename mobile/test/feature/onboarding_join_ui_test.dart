import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/join/join_screen.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_screen.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: MeshTheme.light(), home: child),
    );

void main() {
  group('JoinScreen', () {
    testWidgets('shows the code entry flow by default', (tester) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _app(
          const JoinScreen(),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();

      expect(find.text('Join Room'), findsOneWidget);
      expect(find.text('Join with code'), findsOneWidget);
      expect(find.text('Scan QR instead'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('createRoomOnly hides the code entry and scan controls', (
      tester,
    ) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _app(
          const JoinScreen(createRoomOnly: true),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();

      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join with code'), findsNothing);
      expect(find.text('Scan QR instead'), findsNothing);
      expect(find.text('Name and create room'), findsOneWidget);
    });

    testWidgets('tapping scan toggles the scanner viewport label', (
      tester,
    ) async {
      final db = MeshDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        _app(
          const JoinScreen(),
          overrides: [databaseProvider.overrideWithValue(db)],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Scan QR instead'));
      await tester.pump();

      expect(find.text('Scanning…'), findsOneWidget);
    });
  });

  group('OnboardingScreen validation', () {
    const gestureChannel = MethodChannel('meshsetu/emergency-gestures');

    testWidgets('shows an E.164 validation error for a local contact number', (
      tester,
    ) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(gestureChannel, (call) async {
        if (call.method == 'isEnabled') return true;
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(gestureChannel, null);
      });

      final onboarding = OnboardingRepository(MemoryOnboardingStorage());
      await tester.pumpWidget(
        _app(
          const OnboardingScreen(),
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(onboarding),
          ],
        ),
      );
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Asha Patel');
      await tester.enterText(fields.at(1), '+919876543210');
      await tester.enterText(fields.at(2), 'English');
      await tester.enterText(fields.at(3), 'Ravi Patel');
      await tester.enterText(fields.at(4), '9876543211');

      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(find.text('Save emergency profile'), findsOneWidget);
      await tester.tap(find.text('Save emergency profile'));
      await tester.pump();

      expect(find.textContaining('E.164'), findsOneWidget);
    });
  });
}
