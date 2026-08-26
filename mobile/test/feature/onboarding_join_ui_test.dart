import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/join/join_screen.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_profile.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_screen.dart';
import 'package:meshsetu_mobile/feature/stt/stt_model_manager.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        sttModelManagerProvider.overrideWithValue(
          SttModelManager(manifests: const {}),
        ),
        ...overrides,
      ],
      child: MaterialApp(theme: MeshTheme.light(), home: child),
    );

OnboardingProfile _blankProfile() => OnboardingProfile.create(
  profileId: 'test-profile',
  name: '',
  phone: '',
  language: 'English',
  emergencyContacts: const [],
  medicalProfile: const MedicalProfile(),
);

Future<void> _tapOnboardingButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.drag(find.byType(ListView).first, const Offset(0, -600));
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

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

  group('OnboardingScreen', () {
    testWidgets('moves through the styled sections one at a time', (
      tester,
    ) async {
      final storage = MemoryOnboardingStorage();
      final onboarding = OnboardingRepository(storage);
      await tester.pumpWidget(
        _app(
          OnboardingScreen(initialProfile: _blankProfile(), onComplete: () {}),
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(onboarding),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 3'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('encrypted'), findsNothing);
      expect(find.textContaining('responders'), findsNothing);
      expect(find.text('Your details'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        find.byKey(const Key('preferred-language-dropdown')),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).at(0), 'Asha Patel');
      await tester.enterText(find.byType(TextField).at(1), '+919876543210');
      await tester.tap(find.byKey(const Key('preferred-language-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hindi').last);
      await tester.pumpAndSettle();
      expect(find.text('Hindi ready to be sent via voice.'), findsOneWidget);
      await _tapOnboardingButton(tester, 'Continue');

      expect(find.text('STEP 2 OF 3'), findsOneWidget);
      expect(find.text('Emergency contacts'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).at(0), 'Ravi Patel');
      await tester.enterText(find.byType(TextField).at(1), '+919876543211');
      await _tapOnboardingButton(tester, 'Continue');

      expect(find.text('STEP 3 OF 3'), findsOneWidget);
      expect(find.text('Medical details'), findsOneWidget);
      expect(find.text('Save emergency profile'), findsOneWidget);
      expect(find.textContaining('update these details'), findsNothing);

      await _tapOnboardingButton(tester, 'Save emergency profile');
      expect(storage.value, isNotNull);
      expect(storage.value, contains('"language":"Hindi"'));
    });

    testWidgets('validates a contact number before advancing', (tester) async {
      final onboarding = OnboardingRepository(MemoryOnboardingStorage());
      await tester.pumpWidget(
        _app(
          OnboardingScreen(initialProfile: _blankProfile()),
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(onboarding),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Asha Patel');
      await tester.enterText(find.byType(TextField).at(1), '+919876543210');
      await _tapOnboardingButton(tester, 'Continue');

      await tester.enterText(find.byType(TextField).at(0), 'Ravi Patel');
      await tester.enterText(find.byType(TextField).at(1), '9876543211');
      await _tapOnboardingButton(tester, 'Continue');

      expect(find.textContaining('E.164'), findsOneWidget);
      expect(find.text('STEP 2 OF 3'), findsOneWidget);
    });
  });

  group('Onboarding gesture enrollment', () {
    const gestureChannel = MethodChannel('meshsetu/emergency-gestures');

    testWidgets('requires emergency gestures before continuing', (
      tester,
    ) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(gestureChannel, (call) async {
        if (call.method == 'isEnabled') return false;
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(gestureChannel, null);
      });

      final storage = MemoryOnboardingStorage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(
              OnboardingRepository(storage),
            ),
            sttModelManagerProvider.overrideWithValue(
              SttModelManager(manifests: const {}),
            ),
          ],
          child: MaterialApp(
            home: const OnboardingScreen(requireGestureEnrollment: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Asha Patel');
      await tester.enterText(find.byType(TextField).at(1), '+919876543210');
      await _tapOnboardingButton(tester, 'Continue');

      await tester.enterText(find.byType(TextField).at(0), 'Ravi Patel');
      await tester.enterText(find.byType(TextField).at(1), '+919876543211');
      await _tapOnboardingButton(tester, 'Continue');

      expect(find.text('STEP 3 OF 4'), findsOneWidget);
      expect(find.text('Not enabled'), findsOneWidget);
      await _tapOnboardingButton(tester, 'Continue');

      expect(find.textContaining('Enable Emergency gestures'), findsOneWidget);
      expect(storage.value, isNull);
    });
  });
}
