import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/semver.dart';

void main() {
  group('SemVer', () {
    test('should parse standard versions with or without v prefix', () {
      expect(
        SemVer.tryParse('v1.5.0'),
        const SemVer(major: 1, minor: 5, patch: 0),
      );
      expect(
        SemVer.tryParse('V2.10.3'),
        const SemVer(major: 2, minor: 10, patch: 3),
      );
      expect(
        SemVer.tryParse('1.4.4+9'),
        const SemVer(major: 1, minor: 4, patch: 4),
      );
      expect(
        SemVer.tryParse('v1.5.0-beta.2+12'),
        const SemVer(major: 1, minor: 5, patch: 0, preRelease: ['beta', '2']),
      );
    });

    test('should return null for invalid versions and throw in parse', () {
      expect(SemVer.tryParse(''), isNull);
      expect(SemVer.tryParse('1.5'), isNull);
      expect(SemVer.tryParse('latest'), isNull);
      expect(SemVer.tryParse('v1.2.x'), isNull);
      expect(() => SemVer.parse('invalid'), throwsFormatException);
    });

    test('should compare major, minor, and patch versions accurately', () {
      final v144 = SemVer.parse('1.4.4');
      final v150 = SemVer.parse('v1.5.0');
      final v151 = SemVer.parse('v1.5.1');
      final v200 = SemVer.parse('v2.0.0');

      expect(v150 > v144, isTrue);
      expect(v151 > v150, isTrue);
      expect(v200 > v151, isTrue);
      expect(v144 < v150, isTrue);
      expect(v144 >= SemVer.parse('1.4.4+9'), isTrue);
      expect(v144 <= SemVer.parse('v1.4.4'), isTrue);
    });

    test('should order pre-release versions below stable releases', () {
      final alpha1 = SemVer.parse('1.5.0-alpha.1');
      final alpha2 = SemVer.parse('1.5.0-alpha.2');
      final beta = SemVer.parse('1.5.0-beta');
      final stable = SemVer.parse('1.5.0');

      expect(alpha1 < alpha2, isTrue);
      expect(alpha2 < beta, isTrue);
      expect(beta < stable, isTrue);
      expect(stable > beta, isTrue);
    });
  });
}
