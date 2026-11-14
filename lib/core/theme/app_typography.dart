import 'package:flutter/material.dart';

/// Font families bundled in `assets/fonts/` (see `pubspec.yaml`).
///
/// Static files only, loaded offline: no font is ever fetched at runtime.
abstract final class AppFonts {
  /// Headings. Bundled weights: 500, 700 (optical size fixed at 24 pt).
  static const String heading = 'Bricolage Grotesque';

  /// Body and UI text. Bundled weights: 400, 500, 600, 700.
  static const String body = 'Inter';
}

/// Text theme of the design: headings in [AppFonts.heading], everything else
/// in [AppFonts.body].
///
/// Sizes follow the Material 3 type scale so that text keeps scaling with the
/// system setting; only families, weights and colors are set here.
TextTheme buildAppTextTheme({required Color text, required Color text2}) {
  final base = Typography.material2021().englishLike.apply(
    fontFamily: AppFonts.body,
    displayColor: text,
    bodyColor: text,
  );

  TextStyle heading(TextStyle? style, {double? letterSpacing}) =>
      (style ?? const TextStyle()).copyWith(
        fontFamily: AppFonts.heading,
        fontFamilyFallback: const [AppFonts.body],
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing ?? 0,
      );

  return base.copyWith(
    displayLarge: heading(base.displayLarge, letterSpacing: -0.5),
    displayMedium: heading(base.displayMedium, letterSpacing: -0.5),
    displaySmall: heading(base.displaySmall, letterSpacing: -0.5),
    headlineLarge: heading(base.headlineLarge, letterSpacing: -0.5),
    headlineMedium: heading(base.headlineMedium),
    headlineSmall: heading(base.headlineSmall),
    titleLarge: heading(base.titleLarge),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    bodySmall: base.bodySmall?.copyWith(color: text2),
  );
}
