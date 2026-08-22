import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/ui/components/mesh_components.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_tokens.dart';

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? MeshTheme.dark() : MeshTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('MeshPage', () {
    testWidgets('renders title, actions, and child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshPage(
            title: 'Test title',
            actions: const [Icon(Icons.settings)],
            child: const Text('body content'),
          ),
        ),
      );
      expect(find.text('Test title'), findsOneWidget);
      expect(find.text('body content'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('omits AppBar when title is null', (tester) async {
      await tester.pumpWidget(_wrap(const MeshPage(child: Text('no title'))));
      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('MeshScaffold', () {
    testWidgets('renders large title, subtitle, and sliver content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MeshScaffold(
            title: 'Home',
            subtitle: 'One tap away from help',
            slivers: [
              const SliverToBoxAdapter(child: Text('sliver body')),
            ],
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('One tap away from help'), findsOneWidget);
      expect(find.text('sliver body'), findsOneWidget);
    });
  });

  group('MeshSectionTitle', () {
    testWidgets('renders title and optional subtitle', (tester) async {
      await tester.pumpWidget(
        _wrap(const MeshSectionTitle('Rooms', subtitle: 'Coordinate safely')),
      );
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Coordinate safely'), findsOneWidget);
    });
  });

  group('MeshMicroLabel', () {
    testWidgets('renders label uppercased', (tester) async {
      await tester.pumpWidget(_wrap(const MeshMicroLabel('site id')));
      expect(find.text('SITE ID'), findsOneWidget);
    });
  });

  group('MeshCard', () {
    testWidgets('renders child and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          MeshCard(onTap: () => tapped = true, child: const Text('card body')),
        ),
      );
      expect(find.text('card body'), findsOneWidget);
      await tester.tap(find.byType(MeshCard));
      expect(tapped, isTrue);
    });

    testWidgets('is not wrapped in InkWell when onTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const MeshCard(child: Text('static'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('MeshStatusPill', () {
    testWidgets('critical tone uses ember accent, not the old siren red', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MeshStatusPill(
            label: 'Live',
            tone: MeshStatusTone.critical,
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, MeshPalette.light.ember);
      // The generic siren red (#F51F42) must not appear in the critical
      // tone — MeshColors no longer exposes that value at all (removed in
      // Task 10 once every screen migrated off it).
      expect(icon.color, isNot(const Color(0xFFF51F42)));
    });

    testWidgets('active tone uses the live accent', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MeshStatusPill(label: 'Mesh active', tone: MeshStatusTone.active),
          dark: true,
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, MeshPalette.dark.live);
    });

    testWidgets('carries a semantics label', (tester) async {
      await tester.pumpWidget(_wrap(const MeshStatusPill(label: 'Offline ready')));
      final labeled = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.label != null);
      expect(labeled.map((widget) => widget.properties.label), contains('Offline ready'));
    });
  });

  group('MeshStatRail', () {
    testWidgets('renders every item label and value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MeshStatRail(
            items: [
              MeshStatRailItem(label: 'Peers', value: '3'),
              MeshStatRailItem(label: 'RSSI', value: '-62 dBm', tone: MeshStatusTone.active),
            ],
          ),
        ),
      );
      expect(find.text('PEERS'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('RSSI'), findsOneWidget);
      expect(find.text('-62 dBm'), findsOneWidget);
    });
  });

  group('MeshDataRow', () {
    testWidgets('renders label/value pair with tabular numeric style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const MeshDataRow(label: 'Hop count', value: '2 / 6')),
      );
      expect(find.text('Hop count'), findsOneWidget);
      expect(find.text('2 / 6'), findsOneWidget);
      final valueText = tester.widget<Text>(find.text('2 / 6'));
      expect(
        valueText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('emphasize uses the primary color', (tester) async {
      await tester.pumpWidget(
        _wrap(const MeshDataRow(label: 'Priority', value: 'P0', emphasize: true)),
      );
      final valueText = tester.widget<Text>(find.text('P0'));
      expect(valueText.style?.color, MeshPalette.light.primary);
    });
  });

  group('MeshHeroSurface', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        _wrap(const MeshHeroSurface(child: Text('hero content'))),
      );
      expect(find.text('hero content'), findsOneWidget);
    });

    testWidgets('does not animate when reduced motion is requested', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MeshTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: MeshHeroSurface(child: Text('static hero')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('static hero'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('MeshActionTile', () {
    testWidgets('selected tile tints with primary, not literal red', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MeshActionTile(
            icon: Icons.mic_none_rounded,
            title: 'Voice input',
            subtitle: 'Details ready',
            selected: true,
            onTap: () {},
          ),
        ),
      );
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(MeshCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });

  group('MeshFullWidthButton', () {
    testWidgets('shows a progress indicator when busy', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshFullWidthButton(label: 'Send', busy: true, onPressed: () {}),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Send'), findsNothing);
    });

    testWidgets('secondary variant renders an OutlinedButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MeshFullWidthButton(
            label: 'Cancel',
            secondary: true,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('MeshEmptyState', () {
    testWidgets('renders icon, title, message, and action', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing yet',
            message: 'Come back later',
            action: FilledButton(onPressed: () {}, child: const Text('Retry')),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Come back later'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('MeshEmergencyStep', () {
    testWidgets('complete step uses the live accent check icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const MeshEmergencyStep(
            title: 'Location attached',
            detail: 'GPS captured',
            complete: true,
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, MeshPalette.light.live);
    });
  });

  group('MeshSosButton', () {
    testWidgets('shows SOS label idle and activates after hold', (
      tester,
    ) async {
      var activated = 0;
      await tester.pumpWidget(
        _wrap(
          MeshSosButton(
            holdDuration: const Duration(seconds: 2),
            onActivated: () => activated++,
          ),
        ),
      );
      expect(find.text('SOS'), findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MeshSosButton)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(activated, 0);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(activated, 1);
      await gesture.up();
    });

    testWidgets('carries a descriptive semantics label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MeshSosButton(
            holdDuration: const Duration(seconds: 3),
            onActivated: () {},
          ),
        ),
      );
      final labeled = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((widget) => widget.properties.label != null);
      expect(
        labeled.map((widget) => widget.properties.label),
        contains('SOS emergency. Press and hold for 3 seconds.'),
      );
    });
  });
}
