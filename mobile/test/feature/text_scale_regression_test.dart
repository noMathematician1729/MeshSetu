import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/ble/sos_advertisement.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/home/emergency_home_screen.dart';
import 'package:meshsetu_mobile/feature/join/join_repository.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_profile.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/profile/profile_screen.dart';
import 'package:meshsetu_mobile/feature/rooms/rooms_screen.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

/// Task 10: text-scale regression at the extremes of the range
/// `settings_screen.dart`'s font-size slider allows (0.85x-1.35x), on the
/// three most information-dense rewritten screens. Wraps each screen in a
/// MediaQuery with the target textScaler, the same mechanism `MeshSetuApp`
/// itself uses via `fontScaleProvider` (see `main.dart`'s `builder:`).
Widget _atScale(double scale, Widget child) => MaterialApp(
  theme: MeshTheme.light(),
  builder: (context, materialChild) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: materialChild!,
  ),
  home: child,
);

OnboardingProfile _profile() => OnboardingProfile.create(
  profileId: 'profile-1',
  name: 'Asha Patel',
  phone: '+919876543210',
  language: 'English',
  emergencyContacts: const [
    EmergencyContact(name: 'Ravi Patel', phone: '+919876543211'),
  ],
  medicalProfile: const MedicalProfile(bloodGroup: 'O+', allergies: 'peanuts'),
);

void main() {
  for (final scale in [0.85, 1.35]) {
    group('text scale ${scale}x', () {
      testWidgets('EmergencyHomeScreen renders without overflow', (
        tester,
      ) async {
        await tester.pumpWidget(
          _atScale(
            scale,
            EmergencyHomeScreen(
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
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('RoomsScreen renders without overflow (populated)', (
        tester,
      ) async {
        final db = MeshDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final container = ProviderContainer(
          overrides: [databaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);
        await container
            .read(joinRepositoryProvider)
            .activateManifest(JoinRepository.bundledManifests['DEMO01']!);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _atScale(scale, const RoomsScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('ProfileScreen renders without overflow (populated)', (
        tester,
      ) async {
        final onboarding = OnboardingRepository(MemoryOnboardingStorage());
        await onboarding.save(_profile());
        final container = ProviderContainer(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(onboarding),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _atScale(scale, const ProfileScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
      });
    });
  }
}
