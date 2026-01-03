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

    test('should return hours and minutes when more than 60 and not a multiple', () {
      expect(Formatters.formatRuntime(135), '2h 15m');
    });
  });
}
