import 'package:flutter/material.dart';

/// "Signal" design language tokens.
///
/// Palette rationale: a deep oxblood — not the generic siren red — carries
/// brand and structural weight everywhere. A brighter "ember" red is held in
/// reserve and only appears while an SOS is actually live, so red keeps a
/// single unambiguous meaning: something is happening right now. Mesh /
/// connectivity state uses a cool slate-blue instead, so "red" never gets
/// diluted into meaning Bluetooth status. All pairings below are verified
/// against WCAG 2.1 contrast minimums (4.5:1 body text, 3:1 large text and
/// meaningful graphics) — see `test/ui/theme/mesh_theme_contrast_test.dart`.
abstract final class MeshColors {
  // --- Dark mode (primary experience; a field emergency app is used at
  // night and indoors as often as outdoors) ---
  static const darkCanvas = Color(0xFF120C0D);
  static const darkSurface = Color(0xFF1B1315);
  static const darkSurfaceRaised = Color(0xFF241A1C);
  static const darkHairline = Color(0xFF3A2B2E);
  static const darkText = Color(0xFFF3EDEA);
  static const darkTextMuted = Color(0xFFB9ACA8);

  // --- Light mode (warm bone, not Material's default lavender-white) ---
  static const lightCanvas = Color(0xFFF6F1ED);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceRaised = Color(0xFFFBF5F2);
  static const lightHairline = Color(0xFFE4D9D4);
  static const lightText = Color(0xFF231316);
  static const lightTextMuted = Color(0xFF6B5A57);

  // --- Brand red, tuned per mode so both hit target contrast ---
  static const oxbloodDark = Color(0xFF8C2635);
  static const oxbloodLight = Color(0xFF7A1B2A);
  static const emberDark = Color(0xFFE14757);
  static const emberLight = Color(0xFFB8283A);
  static const onOxbloodDark = Color(0xFFFBEEEF);
  static const onOxbloodLight = Color(0xFFFFFFFF);

  // --- Supporting semantic colors ---
  static const meshDark = Color(0xFF7C9CB8);
  static const meshLight = Color(0xFF3F6E8F);
  static const liveDark = Color(0xFF4FA37D);
  static const liveLight = Color(0xFF2E7D5B);
  static const cautionDark = Color(0xFFE0A741);
  static const cautionLight = Color(0xFF9C6B12);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

/// Resolved semantic roles for the current [Brightness]. Screens that need a
/// palette color not modeled in [ColorScheme] read this instead of branching
/// on `Theme.of(context).brightness` themselves.
class MeshPalette {
  const MeshPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.ember,
    required this.mesh,
    required this.live,
    required this.caution,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color hairline;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color ember;
  final Color mesh;
  final Color live;
  final Color caution;

  static const dark = MeshPalette(
    canvas: MeshColors.darkCanvas,
    surface: MeshColors.darkSurface,
    surfaceRaised: MeshColors.darkSurfaceRaised,
    hairline: MeshColors.darkHairline,
    text: MeshColors.darkText,
    textMuted: MeshColors.darkTextMuted,
    primary: MeshColors.oxbloodDark,
    onPrimary: MeshColors.onOxbloodDark,
    ember: MeshColors.emberDark,
    mesh: MeshColors.meshDark,
    live: MeshColors.liveDark,
    caution: MeshColors.cautionDark,
  );

  static const light = MeshPalette(
    canvas: MeshColors.lightCanvas,
    surface: MeshColors.lightSurface,
    surfaceRaised: MeshColors.lightSurfaceRaised,
    hairline: MeshColors.lightHairline,
    text: MeshColors.lightText,
    textMuted: MeshColors.lightTextMuted,
    primary: MeshColors.oxbloodLight,
    onPrimary: MeshColors.onOxbloodLight,
    ember: MeshColors.emberLight,
    mesh: MeshColors.meshLight,
    live: MeshColors.liveLight,
    caution: MeshColors.cautionLight,
  );

  static MeshPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

abstract final class MeshSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screen = 20.0;
}

abstract final class MeshRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const full = 999.0;
}

abstract final class MeshMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
  static const screen = Duration(milliseconds: 250);
  static const hold = Duration(seconds: 3);
  static const easeOut = Curves.easeOutCubic;
}

/// Dark mode favors a subtle 1px top highlight over drop shadows (shadows
/// read as murky on a near-black canvas). Light mode keeps soft resting/
/// raised elevation shadows since it has room for them.
abstract final class MeshShadows {
  static const resting = [
    BoxShadow(color: Color(0x14231316), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x29231316), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const pressed = [
    BoxShadow(color: Color(0x1A231316), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
