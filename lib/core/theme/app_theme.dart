import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/theme/app_typography.dart';

/// Material color scheme of [palette], written out role by role.
///
/// Nothing is derived from a seed: the primary color is the ink, and no role
/// may fall back to a Material default hue.
ColorScheme buildAppColorScheme(AppPalette palette) {
  return ColorScheme(
    brightness: palette.brightness,
    primary: palette.primary,
    onPrimary: palette.onPrimary,
    primaryContainer: palette.surface2,
    onPrimaryContainer: palette.text,
    secondary: palette.primary,
    onSecondary: palette.onPrimary,
    secondaryContainer: palette.surface2,
    onSecondaryContainer: palette.text,
    tertiary: palette.primary,
    onTertiary: palette.onPrimary,
    tertiaryContainer: palette.surface2,
    onTertiaryContainer: palette.text,
    error: palette.danger,
    onError: palette.onDanger,
    errorContainer: palette.danger,
    onErrorContainer: palette.onDanger,
    surface: palette.surface,
    onSurface: palette.text,
    onSurfaceVariant: palette.text2,
    surfaceDim: palette.surface2,
    surfaceBright: palette.surface,
    surfaceContainerLowest: palette.surface,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surface2,
    surfaceContainerHighest: palette.surface2,
    // Outline of state controls (switch that is off, text field): 3:1.
    outline: palette.stateOutline,
    // Decorative hairlines (dividers, card outlines).
    outlineVariant: palette.border,
    inverseSurface: palette.text,
    onInverseSurface: palette.bg,
    inversePrimary: palette.bg,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );
}

/// Theme of the app for [palette].
ThemeData buildAppTheme(AppPalette palette) {
  final scheme = buildAppColorScheme(palette);
  final textTheme = buildAppTextTheme(text: palette.text, text2: palette.text2);

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
    textTheme: textTheme,
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.surface,
    cardColor: palette.surface,
    dividerColor: palette.border,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Same title alignment on every screen (#202): Flutter centers the
      // title on iOS/macOS when the bar has fewer than two actions.
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: palette.text,
      unselectedItemColor: palette.text2,
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: palette.primary,
      textColor: palette.onPrimary,
    ),
    dialogTheme: DialogThemeData(backgroundColor: palette.surface),
    dividerTheme: DividerThemeData(color: palette.border),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: palette.stateOutline, width: 2),
    ),
    extensions: [palette.toExtension()],
  );
}
