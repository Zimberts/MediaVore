import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/theme/app_theme.dart';

import 'contrast.dart';

/// WCAG 2.x AA thresholds.
const double _aaText = 4.5;
const double _aaNonText = 3.0;

void main() {
  void expectContrast(
    Color foreground,
    Color background,
    double minimum,
    String reason,
  ) {
    final ratio = contrastRatio(foreground, background);
    expect(
      ratio,
      greaterThanOrEqualTo(minimum),
      reason: '$reason: ${ratio.toStringAsFixed(2)}:1, expected $minimum:1',
    );
  }

  group('contrastRatio', () {
    test('should match the WCAG reference values', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      expect(contrastRatio(white, black), closeTo(21, 0.001));
      expect(contrastRatio(white, white), closeTo(1, 0.001));
      // The failure reported by the design review: white on dark "series".
      expect(
        contrastRatio(white, const Color(0xFF8AB0FF)),
        closeTo(2.16, 0.01),
      );
    });
  });

  for (final palette in AppPalette.values) {
    final name = palette.id.name;
    final surfaces = {
      'bg': palette.bg,
      'surface': palette.surface,
      'surface2': palette.surface2,
    };

    group('Contrast on $name', () {
      test('should keep text and secondary text at AA on every surface', () {
        surfaces.forEach((surfaceName, surface) {
          expectContrast(palette.text, surface, _aaText, 'text/$surfaceName');
          expectContrast(palette.text2, surface, _aaText, 'text2/$surfaceName');
        });
      });

      test('should keep content at AA on its fill', () {
        expectContrast(
          palette.onPrimary,
          palette.primary,
          _aaText,
          'onPrimary/primary',
        );
        expectContrast(
          palette.onSeries,
          palette.series,
          _aaText,
          'onSeries/series',
        );
        expectContrast(
          palette.onDanger,
          palette.danger,
          _aaText,
          'onDanger/danger',
        );
      });

      test('should keep media colors at AA on their tint and on pages', () {
        final media = {
          'movie': (palette.movie, palette.movieBg),
          'series': (palette.series, palette.seriesBg),
          'book': (palette.book, palette.bookBg),
          'duo': (palette.duo, palette.duoBg),
        };
        media.forEach((mediaName, colors) {
          final (color, tint) = colors;
          expectContrast(color, tint, _aaText, '$mediaName/${mediaName}Bg');
          expectContrast(color, palette.bg, _aaText, '$mediaName/bg');
          expectContrast(color, palette.surface, _aaText, '$mediaName/surface');
        });
      });

      test('should keep text at AA on media tints (poster without image)', () {
        final tints = {
          'movieBg': palette.movieBg,
          'seriesBg': palette.seriesBg,
          'bookBg': palette.bookBg,
        };
        tints.forEach((tintName, tint) {
          expectContrast(palette.text, tint, _aaText, 'text/$tintName');
          expectContrast(palette.text2, tint, _aaText, 'text2/$tintName');
        });
      });

      test('should keep the selected chip and the message readable', () {
        // Selected filter chip: onPrimary on primary (checked above).
        // Feedback message: bg on text.
        expectContrast(palette.bg, palette.text, _aaText, 'bg/text');
      });

      test('should keep danger at AA as text on every surface', () {
        surfaces.forEach((surfaceName, surface) {
          expectContrast(
            palette.danger,
            surface,
            _aaText,
            'danger/$surfaceName',
          );
        });
      });

      test('should keep success at AA as text on every surface', () {
        surfaces.forEach((surfaceName, surface) {
          expectContrast(
            palette.success,
            surface,
            _aaText,
            'success/$surfaceName',
          );
        });
      });

      test('should keep warning at AA as text on every surface', () {
        surfaces.forEach((surfaceName, surface) {
          expectContrast(
            palette.warning,
            surface,
            _aaText,
            'warning/$surfaceName',
          );
        });
      });

      test('should keep state outlines at 3:1 on every surface', () {
        surfaces.forEach((surfaceName, surface) {
          expectContrast(
            palette.stateOutline,
            surface,
            _aaNonText,
            'stateOutline/$surfaceName',
          );
        });
      });

      test('should keep the roles of legacy screens readable', () {
        final colors = palette.toExtension();
        expectContrast(colors.badgeText, colors.badgeBg, _aaText, 'badge');
        expectContrast(
          colors.badgeText,
          colors.seenBadge,
          _aaText,
          'seen badge',
        );
        expectContrast(
          colors.badgeText,
          colors.ratingStar,
          _aaText,
          'rating chip',
        );
        expectContrast(
          contrastingForeground(colors.success),
          colors.success,
          _aaText,
          'content on success',
        );
        expectContrast(
          colors.text2,
          colors.placeholder,
          _aaText,
          'placeholder',
        );
      });

      test('should give Material state outlines 3:1 through the scheme', () {
        final theme = buildAppTheme(palette);
        final scheme = theme.colorScheme;
        final checkboxSide = theme.checkboxTheme.side!.color;

        surfaces.forEach((surfaceName, surface) {
          // Switch that is off, outlined text field.
          expectContrast(
            scheme.outline,
            surface,
            _aaNonText,
            'outline/$surfaceName',
          );
          // Unchecked checkbox and radio button.
          expectContrast(
            scheme.onSurfaceVariant,
            surface,
            _aaNonText,
            'onSurfaceVariant/$surfaceName',
          );
          expectContrast(
            checkboxSide,
            surface,
            _aaNonText,
            'checkbox/$surfaceName',
          );
        });
        expectContrast(scheme.onPrimary, scheme.primary, _aaText, 'primary');
        expectContrast(scheme.onError, scheme.error, _aaText, 'error');
        expectContrast(scheme.onSurface, scheme.surface, _aaText, 'surface');
        expectContrast(
          scheme.onInverseSurface,
          scheme.inverseSurface,
          _aaText,
          'inverse surface',
        );
        expectContrast(
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
          _aaText,
          'secondary container',
        );
      });
    });
  }
}
