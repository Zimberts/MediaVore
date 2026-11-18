import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  group('AppPalette surfaces', () {
    // Values of the design prototype and preserved legacy palettes.
    const expected = <AppPaletteId, List<int>>{
      AppPaletteId.paper: [0xFFF6F4EF, 0xFFFFFFFF, 0xFFECE8DF, 0xFFDED8CC],
      AppPaletteId.sand: [0xFFF3EDE2, 0xFFFFFCF6, 0xFFE8DFCF, 0xFFDCD0BC],
      AppPaletteId.mist: [0xFFEEF1F4, 0xFFFFFFFF, 0xFFE1E6EC, 0xFFD3DAE2],
      AppPaletteId.ink: [0xFF121110, 0xFF1C1B19, 0xFF292723, 0xFF36332E],
      AppPaletteId.night: [0xFF0E1320, 0xFF161D2E, 0xFF212A3F, 0xFF2C3650],
      AppPaletteId.oled: [0xFF000000, 0xFF0D0D0D, 0xFF1A1A1A, 0xFF262626],
      AppPaletteId.classicLight: [
        0xFFF8F9FA,
        0xFFFFFFFF,
        0xFFECEFF1,
        0xFFCFD8DC,
      ],
      AppPaletteId.parchment: [0xFFFBF0D9, 0xFFFFFDF5, 0xFFF0E4C8, 0xFFE2D6C0],
      AppPaletteId.mint: [0xFFF1F8F3, 0xFFFFFFFF, 0xFFE0EFE4, 0xFFC8E2CF],
      AppPaletteId.solarizedLight: [
        0xFFFDF6E3,
        0xFFFFFDF5,
        0xFFEEE8D5,
        0xFFD3CBB7,
      ],
      AppPaletteId.pinky: [0xFFFDF2F4, 0xFFFFFFFF, 0xFFF8DAE0, 0xFFEDB9C5],
      AppPaletteId.classicDark: [
        0xFF1C1B1F,
        0xFF2B2930,
        0xFF36343C,
        0xFF49454F,
      ],
      AppPaletteId.slate: [0xFF0F172A, 0xFF1E293B, 0xFF283446, 0xFF384556],
      AppPaletteId.midnight: [0xFF0B0F19, 0xFF111827, 0xFF1F2937, 0xFF374151],
      AppPaletteId.espresso: [0xFF1C130E, 0xFF2B1D16, 0xFF3D2B22, 0xFF543E33],
    };

    test(
      'should expose the six core palettes of the design and legacy palettes',
      () {
        expect(AppPalette.coreValues.map((p) => p.id), [
          AppPaletteId.paper,
          AppPaletteId.sand,
          AppPaletteId.mist,
          AppPaletteId.ink,
          AppPaletteId.night,
          AppPaletteId.oled,
        ]);
        expect(AppPalette.values.map((p) => p.id), AppPaletteId.values);
      },
    );

    for (final palette in AppPalette.values) {
      test('should match expected surfaces for ${palette.id.name}', () {
        final values = expected[palette.id]!;
        expect(palette.bg, Color(values[0]));
        expect(palette.surface, Color(values[1]));
        expect(palette.surface2, Color(values[2]));
        expect(palette.border, Color(values[3]));
        expect(palette.brightness, palette.id.brightness);
      });
    }
  });

  group('AppPalette shared tokens', () {
    for (final palette in AppPalette.lightPalettes) {
      test('should match the light prototype for ${palette.id.name}', () {
        expect(palette.text, const Color(0xFF1B1A17));
        expect(palette.text2, const Color(0xFF5C584F));
        expect(palette.primary, const Color(0xFF1B1A17));
        expect(palette.onPrimary, const Color(0xFFFFFFFF));
        expect(palette.movie, const Color(0xFFB23A0A));
        expect(palette.movieBg, const Color(0xFFFBE7DC));
        expect(palette.series, const Color(0xFF1D4ED8));
        expect(palette.seriesBg, const Color(0xFFDFE7FB));
        expect(palette.onSeries, const Color(0xFFFFFFFF));
        expect(palette.book, const Color(0xFF44700C));
        expect(palette.bookBg, const Color(0xFFE5EFD6));
        expect(palette.duo, const Color(0xFF7C3AED));
        expect(palette.duoBg, const Color(0xFFEDE4FD));
        expect(palette.danger, const Color(0xFFB42318));
        expect(palette.onDanger, const Color(0xFFFFFFFF));
        expect(palette.success, const Color(0xFF1A6B33));
      });
    }

    for (final palette in AppPalette.darkPalettes) {
      test('should match the dark prototype for ${palette.id.name}', () {
        expect(palette.text, const Color(0xFFF3F0EA));
        expect(palette.text2, const Color(0xFFABA59A));
        expect(palette.primary, const Color(0xFFF3F0EA));
        expect(palette.onPrimary, const Color(0xFF121110));
        expect(palette.movie, const Color(0xFFFB8A4C));
        expect(palette.movieBg, const Color(0xFF3A2418));
        expect(palette.series, const Color(0xFF8AB0FF));
        expect(palette.seriesBg, const Color(0xFF1C2640));
        expect(palette.onSeries, const Color(0xFF121110));
        expect(palette.book, const Color(0xFFA8CC6E));
        expect(palette.bookBg, const Color(0xFF25301A));
        expect(palette.duo, const Color(0xFFB99BFF));
        expect(palette.duoBg, const Color(0xFF2A2140));
        expect(palette.danger, const Color(0xFFFF9B8A));
        expect(palette.onDanger, const Color(0xFF121110));
        expect(palette.success, const Color(0xFF86D69C));
      });
    }

    test('should use the ink as primary color', () {
      for (final palette in AppPalette.values) {
        expect(palette.primary, palette.text, reason: palette.id.name);
      }
    });

    test('should outline state controls with text2, not border', () {
      for (final palette in AppPalette.values) {
        expect(palette.stateOutline, palette.text2, reason: palette.id.name);
        expect(palette.stateOutline, isNot(palette.border));
      }
    });
  });

  group('AppPalette semantic states', () {
    test('should keep danger separate from media colors', () {
      for (final palette in AppPalette.values) {
        final media = {
          palette.movie,
          palette.series,
          palette.book,
          palette.duo,
        };
        expect(media.contains(palette.danger), isFalse);
        expect(media.contains(palette.success), isFalse);
      }
    });

    test('should map errors and favorites to danger', () {
      final colors = AppPalette.paper.toExtension();
      expect(colors.error, colors.danger);
      expect(colors.likeHeart, colors.danger);
      expect(colors.seenBadge, colors.success);
    });
  });

  group('AppPalette storage', () {
    test('should keep stable storage identifiers', () {
      expect(AppPaletteId.values.map((id) => id.name), [
        'paper',
        'sand',
        'mist',
        'ink',
        'night',
        'oled',
        'classicLight',
        'parchment',
        'mint',
        'solarizedLight',
        'pinky',
        'classicDark',
        'slate',
        'midnight',
        'espresso',
      ]);
    });

    test('should resolve a known identifier', () {
      expect(
        AppPalette.fromStorageId('sand', Brightness.light),
        AppPalette.sand,
      );
      expect(
        AppPalette.fromStorageId('mist', Brightness.light),
        AppPalette.mist,
      );
      expect(
        AppPalette.fromStorageId('mint', Brightness.light),
        AppPalette.mint,
      );
      expect(
        AppPalette.fromStorageId('classicLight', Brightness.light),
        AppPalette.classicLight,
      );
      expect(
        AppPalette.fromStorageId('oled', Brightness.dark),
        AppPalette.oled,
      );
      expect(
        AppPalette.fromStorageId('night', Brightness.dark),
        AppPalette.night,
      );
      expect(
        AppPalette.fromStorageId('classicDark', Brightness.dark),
        AppPalette.classicDark,
      );
    });

    test('should fall back to the default of the brightness', () {
      expect(
        AppPalette.fromStorageId(null, Brightness.light),
        AppPalette.paper,
      );
      expect(
        AppPalette.fromStorageId('unknown_theme', Brightness.light),
        AppPalette.paper,
      );
      expect(
        AppPalette.fromStorageId('sable', Brightness.light),
        AppPalette.paper,
      );
      expect(
        AppPalette.fromStorageId('encre', Brightness.dark),
        AppPalette.ink,
      );
      expect(
        AppPalette.fromStorageId('night', Brightness.light),
        AppPalette.paper,
      );
      expect(
        AppPalette.fromStorageId('paper', Brightness.dark),
        AppPalette.ink,
      );
    });
  });

  group('Default palettes', () {
    test('DefaultLightPalette should resolve to default light (paper)', () {
      expect(const DefaultLightPalette().palette, AppPalette.defaultLight);
      expect(
        const DefaultLightPalette().toThemeData().scaffoldBackgroundColor,
        AppPalette.paper.bg,
      );
    });

    test('DefaultDarkPalette should resolve to default dark (ink)', () {
      expect(const DefaultDarkPalette().palette, AppPalette.defaultDark);
      expect(
        const DefaultDarkPalette().toThemeData().scaffoldBackgroundColor,
        AppPalette.ink.bg,
      );
    });
  });

  group('AppThemeExtension', () {
    test('should copy and lerp every token', () {
      final light = AppPalette.paper.toExtension();
      final dark = AppPalette.ink.toExtension();

      expect(light.copyWith(danger: dark.danger).danger, dark.danger);
      expect(light.copyWith().movie, light.movie);
      expect(light.lerp(dark, 0).bg, light.bg);
      expect(light.lerp(dark, 1).bg, dark.bg);
      expect(light.lerp(dark, 1).onSeries, dark.onSeries);
      expect(light.lerp(null, 0.5), same(light));
    });
  });
}
