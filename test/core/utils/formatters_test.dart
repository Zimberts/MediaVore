import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/formatters.dart';

void main() {
  group('Formatters.formatRuntime', () {
    test('should return empty string when minutes is null', () {
      expect(Formatters.formatRuntime(null), '');
    });

    test('should return empty string when minutes is 0', () {
      expect(Formatters.formatRuntime(0), '');
    });

    test('should return only minutes when less than 60 minutes', () {
      expect(Formatters.formatRuntime(45), '45m');
    });

    test('should return only hours when exactly multiple of 60 minutes', () {
      expect(Formatters.formatRuntime(120), '2h');
    });

    test(
      'should return hours and minutes when more than 60 and not a multiple',
      () {
        expect(Formatters.formatRuntime(135), '2h 15m');
      },
    );
  });

  group('Formatters.formatWatchTime', () {
    test('should use hours and minutes below one day', () {
      expect(Formatters.formatWatchTime(0), '0m');
      expect(Formatters.formatWatchTime(1000), '16h 40m');
    });

    test('should use whole hours below ten days', () {
      expect(Formatters.formatWatchTime(6000), '100h');
      expect(Formatters.formatWatchTime(10000), '166h');
    });

    test('should use days below one year', () {
      expect(Formatters.formatWatchTime(14400), '10 days');
      expect(Formatters.formatWatchTime(60000), '41 days');
    });

    test('should use years from one year', () {
      expect(Formatters.formatWatchTime(525600), '1 year');
      expect(Formatters.formatWatchTime(525600 * 2), '2 years');
      expect(Formatters.formatWatchTime(525600 * 3 ~/ 2), '1.5 years');
    });
  });

  group('Formatters.formatSeasonDuration', () {
    test(
      '10 episodes of 50 min should format as 8,3 h in French and 8.3 h in English',
      () {
        expect(Formatters.formatSeasonDuration(500, locale: 'fr'), '8,3 h');
        expect(Formatters.formatSeasonDuration(500, locale: 'en'), '8.3 h');
      },
    );

    test('should prefix with ~ when isApproximate is true', () {
      expect(
        Formatters.formatSeasonDuration(500, isApproximate: true, locale: 'fr'),
        '~8,3 h',
      );
      expect(
        Formatters.formatSeasonDuration(500, isApproximate: true, locale: 'en'),
        '~8.3 h',
      );
    });

    test('should format exact hours without decimal zero', () {
      expect(Formatters.formatSeasonDuration(60, locale: 'fr'), '1 h');
      expect(Formatters.formatSeasonDuration(120, locale: 'fr'), '2 h');
    });

    test('should format durations under 1 hour in minutes', () {
      expect(Formatters.formatSeasonDuration(45, locale: 'fr'), '45 min');
      expect(
        Formatters.formatSeasonDuration(45, isApproximate: true, locale: 'fr'),
        '~45 min',
      );
    });

    test('should return empty string for zero or negative duration', () {
      expect(Formatters.formatSeasonDuration(0), '');
      expect(Formatters.formatSeasonDuration(-10), '');
    });
  });

  group('Formatters.formatEpisodeDuration', () {
    test('should return empty string for null or <= 0', () {
      expect(Formatters.formatEpisodeDuration(null), '');
      expect(Formatters.formatEpisodeDuration(0), '');
      expect(Formatters.formatEpisodeDuration(-5), '');
    });

    test('should format minutes below 60', () {
      expect(Formatters.formatEpisodeDuration(42), '42 min');
    });

    test('should format exact hours', () {
      expect(Formatters.formatEpisodeDuration(60), '1 h');
      expect(Formatters.formatEpisodeDuration(120), '2 h');
    });

    test('should format hours and minutes', () {
      expect(Formatters.formatEpisodeDuration(75), '1 h 15 min');
    });
  });

  group('Formatters input date localization', () {
    test('inputDatePattern returns localized patterns', () {
      expect(Formatters.inputDatePattern('en'), 'MM/dd/yyyy');
      expect(Formatters.inputDatePattern('en_US'), 'MM/dd/yyyy');
      expect(Formatters.inputDatePattern('fr'), 'dd/MM/yyyy');
      expect(Formatters.inputDatePattern('fr_FR'), 'dd/MM/yyyy');
      expect(Formatters.inputDatePattern(null), 'dd/MM/yyyy');
    });

    test('formatInputDate formats date by locale', () {
      final date = DateTime(2023, 12, 31);
      expect(Formatters.formatInputDate(date, 'en'), '12/31/2023');
      expect(Formatters.formatInputDate(date, 'fr'), '31/12/2023');
    });

    test(
      'parseInputDate strictly parses based on locale and supports fallbacks',
      () {
        final parsedEn = Formatters.parseInputDate('12/31/2023', 'en');
        expect(parsedEn, equals(DateTime(2023, 12, 31)));

        final parsedFr = Formatters.parseInputDate('31/12/2023', 'fr');
        expect(parsedFr, equals(DateTime(2023, 12, 31)));

        // Fallback cross-parsing
        final fallbackFrFromEn = Formatters.parseInputDate('31/12/2023', 'en');
        expect(fallbackFrFromEn, equals(DateTime(2023, 12, 31)));

        // Fallback ISO
        final fallbackIso = Formatters.parseInputDate('2023-12-31', 'en');
        expect(fallbackIso, equals(DateTime(2023, 12, 31)));

        // Invalid returns null
        expect(Formatters.parseInputDate('invalid', 'en'), isNull);
        expect(Formatters.parseInputDate('', 'en'), isNull);
      },
    );
  });
}
