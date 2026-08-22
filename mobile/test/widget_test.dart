import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/main.dart';

void main() {
  testWidgets('shows the SOS-first emergency home', (
    WidgetTester tester,
  ) async {
    final db = MeshDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MeshSetuApp(
          enforcePermissions: false,
          enforceOnboarding: false,
        ),
      ),
    );

    expect(find.text('Emergency Aid'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);

    // The taller hero (Task 4: MeshHeroSurface + MeshStatRail) pushes the
    // secondary controls below the fold in the default test viewport.
    await tester.drag(find.text('Emergency Aid'), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Emergency type'), findsOneWidget);
    expect(find.text('Voice input'), findsOneWidget);
    expect(find.text('Describe SOS'), findsOneWidget);
    expect(find.text('Rooms'), findsWidgets);
    expect(find.text('Discovery funnel'), findsNothing);

    // Task 3: the bottom-nav shell gives every tab a reachable home.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
