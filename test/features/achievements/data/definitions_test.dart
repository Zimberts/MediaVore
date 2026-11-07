import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/utils/genres.dart';

// Validates the real `definitions.json` asset: unlike the repository tests,
// coupling to the file contents is the point here.
void main() {
  late List<Map<String, dynamic>> defs;

  setUpAll(() {
    final content = File(
      'assets/achievements/definitions.json',
    ).readAsStringSync();
    defs = (jsonDecode(content) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  });

  int targetOf(Map<String, dynamic> def) {
    final params = Map<String, dynamic>.from(def['params'] as Map);
    return (params['target'] ?? params['targetMinutes']) as int;
  }

  group('definitions.json', () {
    test('should have unique ids', () {
      final ids = defs.map((d) => d['id']).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('should keep every historical id (persisted unlocks)', () {
      const historicalIds = [
        'movie_1', 'movie_10', 'movie_50', 'movie_100', 'movie_500', //
        'movie_1000', 'tv_1', 'tv_50', 'tv_250', 'tv_1000', 'tv_5000',
        'rewatch_movie_2', 'rewatch_movie_5', 'rewatch_movie_10',
        'rewatch_ep_2', 'rewatch_ep_5', 'loyalist_100', 'loyalist_500',
        'genre_horror', 'genre_horror_50', 'genre_comedy', 'genre_comedy_100',
        'genre_action', 'genre_action_100', 'genre_scifi', 'genre_scifi_100',
        'genre_doc', 'genre_doc_50', 'genre_romance', 'night_owl',
        'night_owl_100', 'weekend_warrior', 'marathon', 'marathon_pro',
        'streak_7', 'streak_30', 'streak_365', 'runtime_1000',
        'runtime_hour_100', 'runtime_10000', 'runtime_day_10',
        'runtime_hour_1000', 'runtime_100000', 'runtime_year_1',
      ];
      final ids = defs.map((d) => d['id']).toSet();
      expect(historicalIds.where((id) => !ids.contains(id)), isEmpty);
    });

    test('should never raise a historical threshold (persisted unlocks)', () {
      // Unlock state is recomputed from history, so raising a target would
      // re-lock users who already earned it. Lowering is safe.
      const maxTargets = {
        'movie_1': 1, 'movie_10': 10, 'movie_50': 50, 'movie_100': 100, //
        'movie_500': 500, 'movie_1000': 1000, 'tv_1': 1, 'tv_50': 50,
        'tv_250': 250, 'tv_1000': 1000, 'tv_5000': 5000,
        'rewatch_movie_2': 2, 'rewatch_movie_5': 5, 'rewatch_movie_10': 10,
        'rewatch_ep_2': 2, 'rewatch_ep_5': 5, 'loyalist_100': 100,
        'loyalist_500': 500, 'genre_horror': 10, 'genre_horror_50': 50,
        'genre_comedy': 20, 'genre_comedy_100': 100, 'genre_action': 20,
        'genre_action_100': 100, 'genre_scifi': 20, 'genre_scifi_100': 100,
        'genre_doc': 10, 'genre_doc_50': 50, 'genre_romance': 15,
        'night_owl': 10, 'night_owl_100': 100, 'weekend_warrior': 15,
        'marathon': 10, 'marathon_pro': 20, 'streak_7': 7, 'streak_30': 30,
        'streak_365': 365, 'runtime_1000': 1000, 'runtime_hour_100': 6000,
        'runtime_10000': 10000, 'runtime_day_10': 14400,
        'runtime_hour_1000': 60000, 'runtime_100000': 100000,
        'runtime_year_1': 525600,
      };
      for (final def in defs) {
        final max = maxTargets[def['id']];
        if (max == null) continue;
        expect(targetOf(def), lessThanOrEqualTo(max), reason: '${def['id']}');
      }
    });

    test('should name every family on its first tier only, in en and fr', () {
      final seen = <String>{};
      for (final def in defs) {
        final group = def['group'] as String?;
        final fr = (def['translations'] as Map?)?['fr'] as Map?;
        if (group != null && seen.add(group)) {
          expect(def['groupTitle'], isA<String>(), reason: group);
          expect(fr?['groupTitle'], isA<String>(), reason: group);
        } else {
          expect(def['groupTitle'], isNull, reason: def['id'] as String);
          expect(fr?['groupTitle'], isNull, reason: def['id'] as String);
        }
      }
    });

    test('should have the required fields on every entry', () {
      for (final def in defs) {
        for (final field in [
          'id',
          'title',
          'description',
          'iconPath',
          'type',
        ]) {
          expect(def[field], isA<String>(), reason: '${def['id']}.$field');
        }
        expect(def['params'], isA<Map>(), reason: '${def['id']}.params');
      }
    });

    test('should only use evaluable types with a positive target', () {
      const types = {
        'count',
        'genre',
        'rewatch',
        'loyalist',
        'behavioral',
        'streak',
        'runtime',
        'marathon',
        'season_complete',
        'series_complete',
        'up_to_date',
        'saga_complete',
        'watchlist_clear',
        'distinct_genres',
        'distinct_countries',
        'distinct_decades',
        'released_before',
        'tmdb_rating',
        'day_one',
        'double_feature',
        'every_weekday',
        'monthly_streak',
        'anniversary',
        'calendar_date',
      };
      for (final def in defs) {
        final params = Map<String, dynamic>.from(def['params'] as Map);
        expect(types, contains(def['type']), reason: def['id'] as String);
        expect(targetOf(def), greaterThan(0), reason: def['id'] as String);
        if (def['type'] == 'behavioral') {
          expect(
            ['night_owl', 'early_bird', 'weekend'],
            contains(params['subtype']),
            reason: def['id'] as String,
          );
        }
        if (def['type'] == 'released_before') {
          expect(params['year'], isA<int>(), reason: def['id'] as String);
        }
        if (def['type'] == 'calendar_date') {
          final dates = params['dates'] as List;
          expect(dates, isNotEmpty, reason: def['id'] as String);
          for (final d in dates) {
            // MM-DD, a real day of a leap year.
            final m = RegExp(r'^(\d{2})-(\d{2})$').firstMatch(d as String);
            expect(m, isNotNull, reason: '${def['id']}: $d');
            final month = int.parse(m!.group(1)!);
            final day = int.parse(m.group(2)!);
            expect(month, inInclusiveRange(1, 12), reason: '${def['id']}: $d');
            expect(
              DateTime(2024, month, day).day,
              day,
              reason: '${def['id']}: $d',
            );
          }
        }
        if (def['type'] == 'tmdb_rating') {
          expect(
            params.keys.toSet().intersection({
              'minRating',
              'minVotes',
              'maxVotes',
            }),
            isNotEmpty,
            reason: def['id'] as String,
          );
        }
        if (def['type'] == 'genre') {
          expect(
            GenreUtils.movieGenres.keys,
            contains(params['genreId']),
            reason: def['id'] as String,
          );
        }
      }
    });

    test('should have consecutive tiers with increasing targets per group', () {
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final def in defs) {
        final group = def['group'] as String?;
        if (group == null) {
          expect(def['tier'], isNull, reason: def['id'] as String);
          continue;
        }
        groups.putIfAbsent(group, () => []).add(def);
      }

      for (final entry in groups.entries) {
        final tiers = entry.value;
        expect(
          tiers.map((d) => d['tier']).toList(),
          List.generate(tiers.length, (i) => i + 1),
          reason: '${entry.key}: tiers must be 1..n in file order',
        );
        expect(
          tiers.map((d) => d['type']).toSet().length,
          1,
          reason: '${entry.key}: a group has a single type',
        );
        for (var i = 1; i < tiers.length; i++) {
          expect(
            targetOf(tiers[i]),
            greaterThan(targetOf(tiers[i - 1])),
            reason: '${entry.key}: targets must increase',
          );
        }
      }
    });
  });
}
