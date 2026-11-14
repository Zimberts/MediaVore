import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/theme/app_theme.dart';
import 'package:mediavore/core/theme/app_typography.dart';

List<Color> _schemeColors(ColorScheme s) => [
  s.primary,
  s.onPrimary,
  s.primaryContainer,
  s.onPrimaryContainer,
  s.primaryFixed,
  s.primaryFixedDim,
  s.onPrimaryFixed,
  s.onPrimaryFixedVariant,
  s.secondary,
  s.onSecondary,
  s.secondaryContainer,
  s.onSecondaryContainer,
  s.secondaryFixed,
  s.secondaryFixedDim,
  s.onSecondaryFixed,
  s.onSecondaryFixedVariant,
  s.tertiary,
  s.onTertiary,
  s.tertiaryContainer,
  s.onTertiaryContainer,
  s.tertiaryFixed,
  s.tertiaryFixedDim,
  s.onTertiaryFixed,
  s.onTertiaryFixedVariant,
  s.error,
  s.onError,
  s.errorContainer,
  s.onErrorContainer,
  s.surface,
  s.onSurface,
  s.onSurfaceVariant,
  s.surfaceDim,
  s.surfaceBright,
  s.surfaceContainerLowest,
  s.surfaceContainerLow,
  s.surfaceContainer,
  s.surfaceContainerHigh,
  s.surfaceContainerHighest,
  s.outline,
  s.outlineVariant,
  s.inverseSurface,
  s.onInverseSurface,
  s.inversePrimary,
  s.shadow,
  s.scrim,
  s.surfaceTint,
];

void main() {
  for (final palette in AppPalette.values) {
    final name = palette.id.name;

    group('buildAppTheme($name)', () {
      final theme = buildAppTheme(palette);
      final scheme = theme.colorScheme;

      test('should use the ink as primary color', () {
        expect(scheme.primary, palette.text);
        expect(scheme.primary, palette.primary);
        expect(scheme.onPrimary, palette.onPrimary);
        expect(scheme.brightness, palette.brightness);
        expect(theme.brightness, palette.brightness);
      });

      test('should only use neutral and danger tokens in the scheme', () {
        final allowed = {
          palette.bg,
          palette.surface,
          palette.surface2,
          palette.text,
          palette.text2,
          palette.border,
          palette.primary,
          palette.onPrimary,
          palette.danger,
          palette.onDanger,
          Colors.black,
          Colors.transparent,
        };
        for (final color in _schemeColors(scheme)) {
          expect(allowed, contains(color));
        }
      });

      test('should leave no hue in the scheme besides danger', () {
        for (final color in _schemeColors(scheme)) {
          if (color == palette.danger || color.a == 0) continue;
          // "Nuit" tints its surfaces slightly; nothing may be vivid.
          final channels = [color.r, color.g, color.b];
          final chroma = channels.reduce(math.max) - channels.reduce(math.min);
          expect(chroma, lessThan(0.25), reason: '$color');
        }
      });

      test('should map surfaces, error and outlines to the tokens', () {
        expect(theme.scaffoldBackgroundColor, palette.bg);
        expect(scheme.surface, palette.surface);
        expect(scheme.onSurface, palette.text);
        expect(scheme.onSurfaceVariant, palette.text2);
        expect(scheme.error, palette.danger);
        expect(scheme.onError, palette.onDanger);
        expect(scheme.outline, palette.text2);
        expect(scheme.outlineVariant, palette.border);
        expect(scheme.surfaceTint, Colors.transparent);
        expect(theme.checkboxTheme.side?.color, palette.text2);
      });

      test('should expose the tokens through the theme extension', () {
        final colors = theme.extension<AppThemeExtension>()!;
        expect(colors.film, palette.film);
        expect(colors.onSerie, palette.onSerie);
        expect(colors.danger, palette.danger);
        expect(colors.success, palette.success);
        expect(colors.stateOutline, palette.text2);
      });

      test('should set headings in Bricolage Grotesque and text in Inter', () {
        final text = theme.textTheme;
        final headings = [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
        ];
        final body = [
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ];
        for (final style in headings) {
          expect(style!.fontFamily, AppFonts.heading);
          expect(style.fontWeight, FontWeight.w700);
          expect(style.color, palette.text);
        }
        for (final style in body) {
          expect(style!.fontFamily, AppFonts.body);
        }
        expect(text.bodyMedium!.color, palette.text);
        expect(text.bodySmall!.color, palette.text2);
        expect(theme.appBarTheme.titleTextStyle!.fontFamily, AppFonts.heading);
      });

      test('should only use bundled font weights', () {
        final bundled = {
          AppFonts.heading: {FontWeight.w500, FontWeight.w700},
          AppFonts.body: {
            FontWeight.w400,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
          },
        };
        final text = theme.textTheme;
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(bundled[style!.fontFamily], contains(style.fontWeight));
        }
      });
    });
  }

  group('App theme in widgets', () {
    Future<void> pump(WidgetTester tester, AppPalette palette) {
      return tester.pumpWidget(
        MaterialApp(
          theme: palette.toThemeData(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Title')),
            body: Column(
              children: [
                const Text('Body'),
                FilledButton(onPressed: () {}, child: const Text('Action')),
                Switch(value: false, onChanged: (_) {}),
                Checkbox(value: false, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
    }

    DefaultTextStyle styleOf(WidgetTester tester, String text) {
      return tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
    }

    for (final palette in [AppPalette.papier, AppPalette.encre]) {
      testWidgets('should render ${palette.id.name} with ink and bundled '
          'fonts', (tester) async {
        await pump(tester, palette);

        final context = tester.element(find.text('Body'));
        expect(context.appColors.primary, palette.text);
        expect(Theme.of(context).colorScheme.primary, palette.text);

        expect(styleOf(tester, 'Title').style.fontFamily, AppFonts.heading);
        expect(styleOf(tester, 'Body').style.fontFamily, AppFonts.body);
        expect(styleOf(tester, 'Body').style.color, palette.text);

        final scaffold = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(Scaffold),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(scaffold.color, palette.bg);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
