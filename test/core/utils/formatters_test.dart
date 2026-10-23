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
}
