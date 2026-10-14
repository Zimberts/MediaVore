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
      };
      for (final def in defs) {
        final params = Map<String, dynamic>.from(def['params'] as Map);
        expect(types, contains(def['type']), reason: def['id'] as String);
        expect(targetOf(def), greaterThan(0), reason: def['id'] as String);
        if (def['type'] == 'behavioral') {
          expect(
            ['night_owl', 'weekend'],
            contains(params['subtype']),
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
