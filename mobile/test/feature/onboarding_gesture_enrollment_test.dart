import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_screen.dart';
import 'package:meshsetu_mobile/feature/stt/stt_model_manager.dart';

Future<void> _tapOnboardingButton(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.drag(find.byType(ListView).first, const Offset(0, -600));
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  const gestureChannel = MethodChannel('meshsetu/emergency-gestures');

  testWidgets('initial Android onboarding requires emergency gestures', (
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
        child: const MaterialApp(
          home: OnboardingScreen(requireGestureEnrollment: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('STEP 1 OF 4'), findsOneWidget);
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
}
