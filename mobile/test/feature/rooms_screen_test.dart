import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/join/join_repository.dart';
import 'package:meshsetu_mobile/feature/rooms/rooms_screen.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(theme: MeshTheme.light(), home: const RoomsScreen()),
);

void main() {
  testWidgets('shows an empty state before joining a site', (tester) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.text('Join an event first'), findsOneWidget);
  });

  testWidgets('lists every readable room for the active site', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await container
        .read(joinRepositoryProvider)
        .activateManifest(JoinRepository.bundledManifests['DEMO01']!);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.text('Public Alerts'), findsOneWidget);
  });

  testWidgets('the room-list screen has no bottom navigation of its own', (
    tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await tester.pumpWidget(_app(container));
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
  });
}
