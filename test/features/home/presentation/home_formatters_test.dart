import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  final now = DateTime(2026, 11, 14, 21);

  group('formatLastActivity', () {
    String ago(AppLocalizations l10n, int days) =>
        formatLastActivity(l10n, now.subtract(Duration(days: days)), now);

    test('should say today and yesterday in words', () {
      expect(ago(en, 0), 'today');
      expect(ago(en, 1), 'yesterday');
      expect(ago(fr, 0), "aujourd'hui");
      expect(ago(fr, 1), 'hier');
    });

    test('should count days under two weeks', () {
      expect(ago(en, 5), '5 d ago');
      expect(ago(fr, 13), 'il y a 13 j');
    });

    test('should count weeks under two months, then months', () {
      expect(ago(fr, 14), 'il y a 2 sem.');
      expect(ago(fr, 59), 'il y a 8 sem.');
      expect(ago(fr, 60), 'il y a 2 mois');
      expect(ago(en, 200), '7 mo ago');
    });

    test('should say today for a date in the future', () {
      expect(
        formatLastActivity(en, now.add(const Duration(days: 2)), now),
        'today',
      );
    });
  });

  group('progressFilterKinds', () {
    test('should offer no filter when a single kind is present', () {
      expect(progressFilterKinds([]), isEmpty);
      expect(progressFilterKinds([MediaKind.series, MediaKind.series]), isEmpty);
    });

    test('should offer the kinds present, in order, from two kinds on', () {
      expect(
        progressFilterKinds([
          MediaKind.book,
          MediaKind.series,
          MediaKind.book,
        ]),
        [MediaKind.series, MediaKind.book],
      );
    });
  });

  group('rotatingPicks', () {
    test('should be empty without candidates', () {
      expect(rotatingPicks(<int>[], 0), isEmpty);
    });

    test('should return every candidate when there are fewer than asked', () {
      expect(rotatingPicks([1, 2], 0), [1, 2]);
    });

    test('should move on with the offset and wrap around', () {
      final candidates = [1, 2, 3, 4, 5];
      expect(rotatingPicks(candidates, 0), [1, 2, 3]);
      expect(rotatingPicks(candidates, 3), [4, 5, 1]);
      expect(rotatingPicks(candidates, 6), [2, 3, 4]);
    });
  });

  group('formatHomeDate', () {
    test('should start with a capital letter', () {
      expect(formatHomeDate(en, now), 'Saturday, November 14');
    });
  });
}
