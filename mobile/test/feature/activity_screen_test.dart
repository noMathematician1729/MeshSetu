import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/core/model/model.dart';
import 'package:meshsetu_mobile/feature/activity/activity_screen.dart';
import 'package:meshsetu_mobile/feature/join/join_repository.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_profile.dart';
import 'package:meshsetu_mobile/feature/onboarding/onboarding_repository.dart';
import 'package:meshsetu_mobile/feature/sos/sos_payload.dart';
import 'package:meshsetu_mobile/feature/sos/sos_repository.dart';
import 'package:meshsetu_mobile/feature/voice/voice_repository.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

const _siteId = 'demo-site';

OnboardingProfile _profile() => OnboardingProfile.create(
  profileId: 'profile-1',
  name: 'Asha',
  phone: '+919876543210',
  language: 'English',
  emergencyContacts: const [
    EmergencyContact(name: 'Ravi', phone: '+919876543211'),
  ],
  medicalProfile: const MedicalProfile(),
);

Future<ProviderContainer> _seededContainer(MeshDatabase db) async {
  final onboarding = OnboardingRepository(MemoryOnboardingStorage());
  await onboarding.save(_profile());
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      onboardingRepositoryProvider.overrideWithValue(onboarding),
    ],
  );
  await container
      .read(joinRepositoryProvider)
      .activateManifest(JoinRepository.bundledManifests['DEMO01']!);
  return container;
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(theme: MeshTheme.light(), home: const ActivityScreen()),
);

void main() {
  testWidgets('shows empty states for all three sections before any activity', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = await _seededContainer(db);
    addTearDown(container.dispose);
    addTearDown(db.close);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.text('SOS outbox'), findsOneWidget);
    expect(find.text('SOS packets you send will appear here.'), findsOneWidget);
    expect(find.text('Received incidents'), findsOneWidget);
    expect(
      find.text('SOS incidents relayed to you over the mesh appear here.'),
      findsOneWidget,
    );
    expect(find.text('Voice evidence'), findsOneWidget);
    expect(
      find.text('Verified voice clips received over the mesh appear here.'),
      findsOneWidget,
    );

    // Drift schedules a zero-duration internal timer when a StreamBuilder's
    // query stream is cancelled at teardown; give it one more pump cycle so
    // flutter_test's strict `!timersPending` check doesn't fire against it.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('lists a drafted SOS in the outbox with its delivery state', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = await _seededContainer(db);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final repo = container.read(sosRepositoryProvider);
    final eventId = await repo.createDraft(
      SosInput(
        siteId: _siteId,
        roomId: 'public',
        inputMode: InputMode.tap,
        rawText: 'Need medical help',
      ),
    );
    await repo.finalizeAndEnqueue(eventId);

    await tester.pumpWidget(_app(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Need medical help'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('lists a received incident and opens its detail on tap', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = await _seededContainer(db);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final payload = StructuredSosPayload(
      incidentType: 'fire',
      transcript: 'Fire near the gate',
      sttConfidence: 0.9,
      triagePriority: PriorityBand.p0Critical,
      triageConfidence: 0.9,
      hazards: const ['fire'],
      rationale: const [],
      inputMode: InputMode.tap,
      reporter: const SosReporter(
        reporterUid: 'aabbccddeeff',
        name: 'Priya',
        phone: '+919000000000',
        language: 'English',
        bloodGroup: '',
        primaryContactName: '',
        primaryContactPhone: '',
      ),
    );
    await db.insertInbox(
      InboxEventsCompanion.insert(
        objectId: const Value(101),
        eventId: 'incident-1',
        siteId: _siteId,
        roomId: 'public',
        payloadType: PayloadType.structuredSos.name,
        payload: payload.encode(),
        peerId: 'peer-1',
        receivedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await tester.pumpWidget(_app(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('fire'), findsOneWidget);
    expect(find.text('From Priya'), findsOneWidget);

    await tester.tap(find.text('fire'));
    await tester.pumpAndSettle();
    expect(find.text('SOS Incident'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows a voice-evidence count and links to VoiceInboxScreen', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = await _seededContainer(db);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final voicePayload = VoiceObjectPayload(
      sosEventId: 'sos-1',
      clipId: 'clip-1',
      bytes: Uint8List.fromList(List.generate(32, (i) => i)),
    );
    await db.insertInbox(
      InboxEventsCompanion.insert(
        objectId: const Value(202),
        eventId: 'voice-1',
        siteId: _siteId,
        roomId: 'public',
        payloadType: PayloadType.voiceObject.name,
        payload: voicePayload.encode(),
        peerId: 'peer-2',
        receivedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await tester.pumpWidget(_app(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('1 voice clip received'), findsOneWidget);

    await tester.tap(find.text('1 voice clip received'));
    await tester.pumpAndSettle();
    expect(find.text('Voice Evidence'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
