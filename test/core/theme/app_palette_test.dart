import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/theme/app_palette.dart';

void main() {
  group('AppPalette surfaces', () {
    // Values of the design prototype: bg, surface, surface2, border.
    const expected = <AppPaletteId, List<int>>{
      AppPaletteId.papier: [0xFFF6F4EF, 0xFFFFFFFF, 0xFFECE8DF, 0xFFDED8CC],
      AppPaletteId.sable: [0xFFF3EDE2, 0xFFFFFCF6, 0xFFE8DFCF, 0xFFDCD0BC],
      AppPaletteId.brume: [0xFFEEF1F4, 0xFFFFFFFF, 0xFFE1E6EC, 0xFFD3DAE2],
      AppPaletteId.encre: [0xFF121110, 0xFF1C1B19, 0xFF292723, 0xFF36332E],
      AppPaletteId.nuit: [0xFF0E1320, 0xFF161D2E, 0xFF212A3F, 0xFF2C3650],
      AppPaletteId.oled: [0xFF000000, 0xFF0D0D0D, 0xFF1A1A1A, 0xFF262626],
    };

    test('should expose exactly the six palettes of the design', () {
      expect(AppPalette.values.map((p) => p.id), AppPaletteId.values);
      expect(AppPalette.lightPalettes.map((p) => p.id), [
        AppPaletteId.papier,
        AppPaletteId.sable,
        AppPaletteId.brume,
      ]);
      expect(AppPalette.darkPalettes.map((p) => p.id), [
        AppPaletteId.encre,
        AppPaletteId.nuit,
        AppPaletteId.oled,
      ]);
    });

    for (final palette in AppPalette.values) {
      test('should match the prototype for ${palette.id.name}', () {
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
        expect(palette.film, const Color(0xFFB23A0A));
        expect(palette.filmBg, const Color(0xFFFBE7DC));
        expect(palette.serie, const Color(0xFF1D4ED8));
        expect(palette.serieBg, const Color(0xFFDFE7FB));
        expect(palette.onSerie, const Color(0xFFFFFFFF));
        expect(palette.livre, const Color(0xFF44700C));
        expect(palette.livreBg, const Color(0xFFE5EFD6));
        expect(palette.duo, const Color(0xFF7C3AED));
        expect(palette.duoBg, const Color(0xFFEDE4FD));
        expect(palette.danger, const Color(0xFFB42318));
        expect(palette.onDanger, const Color(0xFFFFFFFF));
        expect(palette.success, const Color(0xFF1E7A3A));
      });
    }

    for (final palette in AppPalette.darkPalettes) {
      test('should match the dark prototype for ${palette.id.name}', () {
        expect(palette.text, const Color(0xFFF3F0EA));
        expect(palette.text2, const Color(0xFFABA59A));
        expect(palette.primary, const Color(0xFFF3F0EA));
        expect(palette.onPrimary, const Color(0xFF121110));
        expect(palette.film, const Color(0xFFFB8A4C));
        expect(palette.filmBg, const Color(0xFF3A2418));
        expect(palette.serie, const Color(0xFF8AB0FF));
        expect(palette.serieBg, const Color(0xFF1C2640));
        expect(palette.onSerie, const Color(0xFF121110));
        expect(palette.livre, const Color(0xFFA8CC6E));
        expect(palette.livreBg, const Color(0xFF25301A));
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
    test('should never reuse a media color for a state', () {
      for (final palette in AppPalette.values) {
        final media = {palette.film, palette.serie, palette.livre, palette.duo};
        final colors = palette.toExtension();
        final states = {
          'danger': colors.danger,
          'success': colors.success,
          'warning': colors.warning,
          'error': colors.error,
          'likeHeart': colors.likeHeart,
          'onWatchlist': colors.onWatchlist,
          'seenBadge': colors.seenBadge,
          'badgeBg': colors.badgeBg,
          'ratingStar': colors.ratingStar,
        };
        states.forEach((name, color) {
          expect(
            media.contains(color),
            isFalse,
            reason: '$name on ${palette.id.name}',
          );
        });
      }
    });

    test('should map errors and favorites to danger', () {
      final colors = AppPalette.papier.toExtension();
      expect(colors.error, colors.danger);
      expect(colors.likeHeart, colors.danger);
      expect(colors.seenBadge, colors.success);
    });
  });

  group('AppPalette storage', () {
    test('should keep stable storage identifiers', () {
      expect(AppPaletteId.values.map((id) => id.name), [
        'papier',
        'sable',
        'brume',
        'encre',
        'nuit',
        'oled',
      ]);
    });

    test('should resolve a known identifier', () {
      expect(
        AppPalette.fromStorageId('sable', Brightness.light),
        AppPalette.sable,
      );
      expect(
        AppPalette.fromStorageId('oled', Brightness.dark),
        AppPalette.oled,
      );
    });

    test('should fall back to the default of the brightness', () {
      expect(
        AppPalette.fromStorageId(null, Brightness.light),
        AppPalette.papier,
      );
      expect(
        AppPalette.fromStorageId('mint', Brightness.light),
        AppPalette.papier,
      );
      expect(
        AppPalette.fromStorageId('nuit', Brightness.light),
        AppPalette.papier,
      );
      expect(
        AppPalette.fromStorageId('papier', Brightness.dark),
        AppPalette.encre,
      );
    });
  });

  group('AppThemeExtension', () {
    test('should copy and lerp every token', () {
      final light = AppPalette.papier.toExtension();
      final dark = AppPalette.encre.toExtension();

      expect(light.copyWith(danger: dark.danger).danger, dark.danger);
      expect(light.copyWith().film, light.film);
      expect(light.lerp(dark, 0).bg, light.bg);
      expect(light.lerp(dark, 1).bg, dark.bg);
      expect(light.lerp(dark, 1).onSerie, dark.onSerie);
      expect(light.lerp(null, 0.5), same(light));
    });
  });
}
