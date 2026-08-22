import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_theme.dart';
import 'package:meshsetu_mobile/ui/theme/mesh_tokens.dart';

/// WCAG 2.1 relative luminance, per spec formula.
double _linearize(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('MeshPalette WCAG contrast', () {
    for (final entry in {
      'dark': MeshPalette.dark,
      'light': MeshPalette.light,
    }.entries) {
      final mode = entry.key;
      final palette = entry.value;

      test('$mode: body text on canvas >= 4.5:1', () {
        expect(
          _contrastRatio(palette.text, palette.canvas),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$mode: body text on surface >= 4.5:1', () {
        expect(
          _contrastRatio(palette.text, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$mode: muted text on surface >= 4.5:1', () {
        expect(
          _contrastRatio(palette.textMuted, palette.surface),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$mode: onPrimary on primary >= 4.5:1', () {
        expect(
          _contrastRatio(palette.onPrimary, palette.primary),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$mode: ember accent on canvas >= 3:1 (large text/graphics)', () {
        expect(
          _contrastRatio(palette.ember, palette.canvas),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('$mode: mesh accent on canvas >= 3:1', () {
        expect(
          _contrastRatio(palette.mesh, palette.canvas),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('$mode: live accent on canvas >= 3:1', () {
        expect(
          _contrastRatio(palette.live, palette.canvas),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('$mode: caution accent on canvas >= 3:1', () {
        expect(
          _contrastRatio(palette.caution, palette.canvas),
          greaterThanOrEqualTo(3.0),
        );
      });
    }
  });

  group('MeshTheme high contrast', () {
    test('light high-contrast outline resolves to full text color', () {
      final theme = MeshTheme.light(highContrast: true);
      expect(theme.colorScheme.outline, MeshPalette.light.text);
    });

    test('dark high-contrast outline resolves to full text color', () {
      final theme = MeshTheme.dark(highContrast: true);
      expect(theme.colorScheme.outline, MeshPalette.dark.text);
    });
  });

  group('MeshTheme typography', () {
    test('body text uses the bundled Inter family', () {
      final theme = MeshTheme.light();
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    });

    test('headings use the bundled Space Grotesk family', () {
      final theme = MeshTheme.light();
      expect(theme.textTheme.headlineSmall?.fontFamily, 'Space Grotesk');
      expect(theme.textTheme.displaySmall?.fontFamily, 'Space Grotesk');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Space Grotesk');
    });

    test('numeric style carries tabular figures', () {
      final theme = MeshTheme.dark();
      final numeric = theme.extension<MeshNumericStyle>();
      expect(numeric, isNotNull);
      expect(
        numeric!.style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
