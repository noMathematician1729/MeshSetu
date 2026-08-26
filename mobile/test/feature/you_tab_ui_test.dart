import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/feature/gateway/gateway_screen.dart';
import 'package:meshsetu_mobile/feature/location/location_screen.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_profile.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/profile/profile_screen.dart';
import 'package:meshsetu_mobile/feature/profile/settings_screen.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';
import 'package:meshsetu_mobile/ui/theme/theme_controller.dart';

OnboardingProfile _profile() => OnboardingProfile.create(
  profileId: 'profile-1',
  name: 'Asha',
  phone: '+919876543210',
  language: 'English',
  emergencyContacts: const [
    EmergencyContact(name: 'Ravi', phone: '+919876543211', priority: 1),
  ],
  medicalProfile: const MedicalProfile(bloodGroup: 'O+'),
);

ProviderContainer _container({OnboardingRepository? onboarding}) =>
    ProviderContainer(
      overrides: [
        if (onboarding != null)
          onboardingRepositoryProvider.overrideWithValue(onboarding),
      ],
    );

Widget _app(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: MeshTheme.light(), home: child),
    );

void main() {
  group('ProfileScreen', () {
    testWidgets('shows the create-profile empty state when none exists', (
      tester,
    ) async {
      final onboarding = OnboardingRepository(MemoryOnboardingStorage());
      final container = _container(onboarding: onboarding);
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const ProfileScreen()));
      await tester.pump();

      expect(find.text('Create your emergency profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders a populated profile without ListTile rendering errors',
      (tester) async {
        final onboarding = OnboardingRepository(MemoryOnboardingStorage());
        await onboarding.save(_profile());
        final container = _container(onboarding: onboarding);
        addTearDown(container.dispose);

        await tester.pumpWidget(_app(container, const ProfileScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('Asha'), findsOneWidget);
        expect(find.text('O+'), findsOneWidget);
        expect(find.text('Ravi'), findsOneWidget);
        // The pre-existing bug (Task 3 finding): ListTile placed directly
        // inside MeshCard's DecoratedBox with no Material ancestor threw
        // "ListTile background color or ink splashes may be invisible."
        // This rewrite drops ListTile in favor of plain Row layouts, so no
        // exception should surface here.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('keeps the full language list scrollable on a short screen', (
      tester,
    ) async {
      final onboarding = OnboardingRepository(MemoryOnboardingStorage());
      await onboarding.save(_profile());
      final container = _container(onboarding: onboarding);
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(360, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(container, const ProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preferred language'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders every section without ListTile rendering errors', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Accessibility'), findsOneWidget);
      expect(find.text('Emergency settings'), findsOneWidget);
      expect(find.text('Connectivity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling dark mode updates the provider state', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const SettingsScreen()));
      await tester.pump();

      expect(container.read(darkModeProvider), isFalse);
      final darkModeSwitches = find.byType(Switch);
      await tester.tap(darkModeSwitches.at(1));
      await tester.pump();

      expect(container.read(darkModeProvider), isTrue);
    });

    testWidgets('toggling high contrast updates the provider state', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const SettingsScreen()));
      await tester.pump();

      expect(container.read(highContrastProvider), isFalse);
      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(container.read(highContrastProvider), isTrue);
    });

    testWidgets('navigates to LocationScreen', (tester) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const SettingsScreen()));
      await tester.pump();

      await tester.tap(find.text('Location details'));
      await tester.pumpAndSettle();

      expect(find.byType(LocationScreen), findsOneWidget);
    });

    testWidgets('navigates to GatewayScreen without rendering errors', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const SettingsScreen()));
      await tester.pump();

      await tester.ensureVisible(find.text('Emergency gateway'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emergency gateway'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GatewayScreen), findsOneWidget);
      expect(find.text('Act as emergency gateway'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('LocationScreen', () {
    testWidgets('renders the capture prompt with no location yet', (
      tester,
    ) async {
      final container = _container();
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, const LocationScreen()));
      await tester.pump();

      expect(find.text('Location not captured'), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);
    });
  });
}
