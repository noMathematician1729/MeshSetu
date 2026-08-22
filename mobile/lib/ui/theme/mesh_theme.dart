import 'package:flutter/material.dart';

import 'mesh_tokens.dart';

/// "Signal" theme: Space Grotesk for display/headings, Inter for body/UI,
/// both vendored locally (see pubspec.yaml `fonts:`) so the app never makes
/// a network call for typography — consistent with its offline-first design.
abstract final class MeshTheme {
  static ThemeData light({bool highContrast = false}) =>
      _theme(Brightness.light, highContrast: highContrast);

  static ThemeData dark({bool highContrast = false}) =>
      _theme(Brightness.dark, highContrast: highContrast);

  static ThemeData _theme(Brightness brightness, {required bool highContrast}) {
    final dark = brightness == Brightness.dark;
    final palette = dark ? MeshPalette.dark : MeshPalette.light;
    final outline = highContrast
        ? palette.text
        : palette.hairline;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: dark
          ? const Color(0xFF3D1319)
          : const Color(0xFFF6DEE1),
      onPrimaryContainer: dark ? MeshColors.onOxbloodDark : palette.primary,
      secondary: palette.mesh,
      onSecondary: MeshColors.white,
      secondaryContainer: dark
          ? const Color(0xFF1C2A34)
          : const Color(0xFFE3EEF5),
      onSecondaryContainer: palette.mesh,
      tertiary: palette.live,
      onTertiary: MeshColors.white,
      error: palette.ember,
      onError: MeshColors.white,
      errorContainer: dark
          ? const Color(0xFF3D1319)
          : const Color(0xFFF6DEE1),
      onErrorContainer: palette.ember,
      surface: palette.canvas,
      onSurface: palette.text,
      surfaceContainerHighest: palette.surfaceRaised,
      onSurfaceVariant: palette.textMuted,
      outline: outline,
      outlineVariant: outline,
      shadow: MeshColors.black,
      scrim: MeshColors.black,
      inverseSurface: dark ? palette.text : MeshColors.darkCanvas,
      onInverseSurface: dark ? MeshColors.darkCanvas : palette.text,
      inversePrimary: palette.ember,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
    );

    // Display/heading scale rides Space Grotesk; body/UI stays on Inter.
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Space Grotesk',
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: 'Space Grotesk',
        fontSize: 24,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'Space Grotesk',
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.45,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      textTheme: text.apply(bodyColor: palette.text, displayColor: palette.text),
      // Custom extension: tabular-figure style for telemetry (RSSI, hop
      // counts, object IDs, coordinates) so digits don't jitter as they
      // update. Read via `Theme.of(context).extension<MeshNumericStyle>()`.
      extensions: [
        MeshNumericStyle(
          style: text.bodyMedium!.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: palette.canvas,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall?.copyWith(color: palette.text),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x29231316),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: outline, width: highContrast ? 1.5 : 1),
          borderRadius: BorderRadius.circular(MeshRadius.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          disabledBackgroundColor: dark
              ? const Color(0xFF3A2E30)
              : const Color(0xFFDCD1CD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeshRadius.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: palette.text,
          side: BorderSide(color: outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MeshRadius.md),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.all(MeshSpace.md),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(palette.primary, width: 1.5),
        errorBorder: _inputBorder(palette.ember),
        focusedErrorBorder: _inputBorder(palette.ember, width: 1.5),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      // Restrained shared-axis transition (fade + slight forward/back
      // translation) for every MaterialPageRoute push in the app — this is
      // Flutter's built-in FadeForwardsPageTransitionsBuilder, whose
      // AnimationController already shortens/skips itself automatically
      // when MediaQuery.disableAnimationsOf is true, so no manual reduced-
      // motion gating is needed here.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : (dark ? const Color(0xFF3A2E30) : const Color(0xFFDCD1CD)),
        ),
        thumbColor: const WidgetStatePropertyAll(MeshColors.white),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: palette.primary,
        inactiveTrackColor: outline,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: outline,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceRaised,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MeshRadius.full),
        ),
        labelStyle: text.labelMedium?.copyWith(color: palette.text),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(MeshRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Theme extension carrying the tabular-figure numeric text style used for
/// telemetry: RSSI, hop counts, object IDs, GPS coordinates.
class MeshNumericStyle extends ThemeExtension<MeshNumericStyle> {
  const MeshNumericStyle({required this.style});

  final TextStyle style;

  @override
  MeshNumericStyle copyWith({TextStyle? style}) =>
      MeshNumericStyle(style: style ?? this.style);

  @override
  MeshNumericStyle lerp(ThemeExtension<MeshNumericStyle>? other, double t) {
    if (other is! MeshNumericStyle) return this;
    return MeshNumericStyle(style: TextStyle.lerp(style, other.style, t)!);
  }
}
