import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshsetu_mobile/app/mesh_shell.dart';
import 'package:meshsetu_mobile/app/providers.dart';
import 'package:meshsetu_mobile/core/data/database.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';

void main() {
  testWidgets('describe SOS sheet closes without inherited-element errors', (
    tester,
  ) async {
    final database = MeshDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(theme: MeshTheme.light(), home: const MeshShell()),
      ),
    );
    await tester.pump();
    expect(find.text('Emergency Aid'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();

    await tester.tap(find.text('Describe SOS'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Save details'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Emergency details');
    await tester.ensureVisible(find.text('Save details'));
    await tester.tap(find.text('Save details'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Emergency details'), findsOneWidget);
  });
}
