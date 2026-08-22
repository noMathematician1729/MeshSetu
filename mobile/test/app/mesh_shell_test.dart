import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/app/mesh_shell.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/feature/activity/activity_screen.dart';
import 'package:meshsetu_mobile/feature/rooms/rooms_screen.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

/// [MeshShell] tests (Task 3 of the UI revamp): tab switching and per-tab
/// [Navigator] stack preservation.
///
/// These use bounded `tester.pump(duration)` calls rather than
/// `pumpAndSettle`: the Home tab renders `EventModeScreen`, whose SOS button
/// runs a continuously-repeating pulse `AnimationController`
/// (`MeshSosButton._pulse`), so `pumpAndSettle` never terminates —
/// `test/widget_test.dart` established this same pattern for the same
/// reason.
///
/// The "You" tab hosts `ProfileScreen`, which has a pre-existing rendering
/// issue unrelated to the shell — a `ListTile` placed directly inside
/// `MeshCard`'s `DecoratedBox` with no intervening `Material` ancestor,
/// which Flutter's framework flags as "ListTile background color or ink
/// splashes may be invisible." This predates the nav-shell work and is in
/// Task 8's scope (You tab and settings surfaces), so these tests avoid
/// asserting on the You tab's internal content and instead verify tab-bar
/// mechanics using the Home, Rooms, and Activity tabs.
Widget _shellApp() {
  final db = MeshDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(theme: MeshTheme.light(), home: const MeshShell()),
  );
}

void main() {
  testWidgets('renders all four tab destinations', (tester) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rooms'), findsWidgets);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('starts on the Home tab showing the SOS hero', (tester) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    expect(find.text('Emergency Aid'), findsOneWidget);
  });

  testWidgets('switching to Rooms shows the Rooms tab root', (tester) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Rooms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(RoomsScreen), findsOneWidget);
    expect(find.byType(ActivityScreen), findsNothing);
  });

  testWidgets('switching to Activity shows the Activity tab root', (
    tester,
  ) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Activity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ActivityScreen), findsOneWidget);
  });

  testWidgets('switching tabs preserves each tab in an IndexedStack', (
    tester,
  ) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Rooms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // An IndexedStack keeps every tab's widget subtree alive (Offstage,
    // not removed), rather than rebuilding it from scratch on return.
    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.text('Emergency Aid'), findsOneWidget);
  });

  testWidgets('re-tapping the active tab does not throw', (tester) async {
    await tester.pumpWidget(_shellApp());
    await tester.pump();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Home'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Emergency Aid'), findsOneWidget);
  });
}
