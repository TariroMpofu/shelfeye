import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PriceCheck kiosk design system. Warm paper surfaces, ink text scale, single
/// emerald accent reserved for price/value/confirm. Schibsted Grotesk for UI,
/// IBM Plex Mono for codes, prices and small uppercase labels.
///
/// Colours are the sRGB equivalents of the handoff's oklch tokens.
class AppTheme {
  // Surfaces
  static const Color paper = Color(0xFFFBFAF7); // --paper
  static const Color paper2 = Color(0xFFF6F4EF); // --paper-2
  static const Color surface = Color(0xFFFFFFFF); // --surface (cards)

  // Ink scale
  static const Color ink = Color(0xFF211F1B); // --ink (primary / dark buttons)
  static const Color inkSoft = Color(0xFF5E5A54); // --ink-soft
  static const Color muted = Color(0xFF8C8881); // --muted
  static const Color faint = Color(0xFFB0ACA6); // --faint

  // Lines
  static const Color line = Color(0xFFE6E4DF); // --line
  static const Color line2 = Color(0xFFF0EEEA); // --line-2

  // Accent (emerald) + derived washes
  static const Color accent = Color(0xFF1F7A52); // --accent
  static const Color accentWash = Color(0xFFE9F2EE); // accent @10% over surface
  static const Color accentLine = Color(0xFFC0DACF); // accent @28% over surface

  static const Color danger = Color(0xFFC03A28); // --danger

  // Radii
  static const double radius = 20; // buttons / inputs
  static const double radiusLg = 28; // cards
  static const double radiusXl = 36; // price hero
  static const double radiusPill = 999;
  static const double radiusChip = 8;

  // Shadows
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0A1E1C18), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x141E1C18),
      blurRadius: 28,
      spreadRadius: -16,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x0D1E1C18), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(
      color: Color(0x261E1C18),
      blurRadius: 60,
      spreadRadius: -30,
      offset: Offset(0, 24),
    ),
  ];

  /// UI font (Schibsted Grotesk). `letterSpacing` is expressed as an em factor
  /// (matching the handoff's `-.03em` style values).
  static TextStyle sans({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double letterSpacingEm = -0.01,
    double? height,
  }) => GoogleFonts.schibstedGrotesk(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? ink,
    letterSpacing: letterSpacingEm * fontSize,
    height: height,
  );

  /// Mono font (IBM Plex Mono) for codes, prices, endpoints, small labels.
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacingEm = 0,
    double? height,
  }) => GoogleFonts.ibmPlexMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? ink,
    letterSpacing: letterSpacingEm * fontSize,
    height: height,
  );

  /// Tabular numerals for prices.
  static TextStyle monoTabular({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacingEm = 0,
    double? height,
  }) => mono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacingEm: letterSpacingEm,
    height: height,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Small uppercase mono label (e.g. price-hero label, group titles).
  static TextStyle label({Color? color, double fontSize = 13}) => mono(
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    color: color ?? muted,
    letterSpacingEm: 0.08,
  );

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: ink,
      brightness: Brightness.light,
      primary: ink,
      onPrimary: paper,
      surface: paper,
      onSurface: ink,
      error: danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      textTheme: GoogleFonts.schibstedGroteskTextTheme().apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
