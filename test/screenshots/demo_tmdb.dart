/// Offline stand-in for the TMDB API, built on [demoCatalog].
///
/// [DemoTmdbInterceptor] answers every `api.themoviedb.org` request made by
/// the app's real `Dio` with TMDB-shaped JSON, so the whole app (repository,
/// Isar cache, providers, pages) runs unchanged without network or API key.
library;

import 'package:dio/dio.dart';

import 'demo_catalog.dart';

class DemoTmdb {
  DemoTmdb({required this.now, this.language = 'fr'});

  /// Reference date: release and air dates are placed relative to it so that
  /// "upcoming" episodes stay upcoming whenever the screenshots are taken.
  final DateTime now;
  final String language;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _genres(DemoMedia m) => [
    for (final id in m.genres)
      {
        'id': id,
        'name': language == 'fr' ? demoGenres[id]!.$1 : demoGenres[id]!.$2,
      },
  ];

  /// Air date of episode [episode] (1-based) of season [season] (1-based).
  DateTime airDate(DemoMedia m, int season, int episode) {
    final count = m.seasons[season - 1];
    if (count < 0) {
      // Airing season: half of the episodes are out, one per week.
      final aired = (-count) ~/ 2;
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: 7 * (episode - aired) - 3));
    }
    return DateTime(
      m.year + season - 1,
      3,
      1,
    ).add(Duration(days: 7 * (episode - 1)));
  }

  Map<String, dynamic> _episode(DemoMedia m, int season, int episode) => {
    'id': m.id * 1000 + season * 100 + episode,
    'season_number': season,
    'episode_number': episode,
    'name': language == 'fr' ? 'Épisode $episode' : 'Episode $episode',
    'air_date': _date(airDate(m, season, episode)),
    'runtime': m.runtime,
    'overview': '',
    'still_path': null,
    'vote_average': m.rating,
  };

  Map<String, dynamic> season(DemoMedia m, int season) {
    final count = m.seasons[season - 1].abs();
    return {
      'id': m.id * 1000 + season,
      'season_number': season,
      'name': language == 'fr' ? 'Saison $season' : 'Season $season',
      'air_date': _date(airDate(m, season, 1)),
      'episode_count': count,
      'poster_path': m.posterPath,
      'overview': '',
      'episodes': [for (var e = 1; e <= count; e++) _episode(m, season, e)],
    };
  }

  /// The list-shaped item returned by search, discover, similar...
  Map<String, dynamic> summary(DemoMedia m) => {
    'id': m.id,
    'media_type': m.mediaType,
    m.isTv ? 'name' : 'title': m.title(language),
    m.isTv ? 'original_name' : 'original_title': m.originalTitle,
    m.isTv ? 'first_air_date' : 'release_date': _date(
      m.isTv ? airDate(m, 1, 1) : DateTime(m.year, 6, 15),
    ),
    'overview': m.overview(language),
    'poster_path': m.posterPath,
    'backdrop_path': m.backdropPath,
    'genre_ids': m.genres,
    'genres': _genres(m),
    'vote_average': m.rating,
    'vote_count': m.voteCount,
    'popularity': m.popularity,
    'original_language': m.language,
    if (m.isTv) 'origin_country': [m.country],
  };

  Map<String, dynamic> details(DemoMedia m) {
    final data = summary(m)..remove('genre_ids');
    if (!m.isTv) {
      data['runtime'] = m.runtime;
      data['status'] = 'Released';
      data['production_countries'] = [
        {'iso_3166_1': m.country, 'name': m.country},
      ];
      if (m.collection != null) {
        data['belongs_to_collection'] = {
          'id': m.collection!.$1,
          'name': m.collection!.$2,
        };
      }
      return data;
    }

    final episodes = <Map<String, dynamic>>[
      for (var s = 1; s <= m.seasons.length; s++)
        for (var e = 1; e <= m.seasons[s - 1].abs(); e++) _episode(m, s, e),
    ];
    final today = DateTime(now.year, now.month, now.day);
    final aired = episodes
        .where((e) => !DateTime.parse(e['air_date'] as String).isAfter(today))
        .toList();
    final upcoming = episodes
        .where((e) => DateTime.parse(e['air_date'] as String).isAfter(today))
        .toList();
    final airing = m.seasons.any((c) => c < 0);
    data.addAll({
      'episode_run_time': [m.runtime],
      'number_of_seasons': m.seasons.length,
      'number_of_episodes': episodes.length,
      'status': airing || m.id == 136315 ? 'Returning Series' : 'Ended',
      'in_production': airing,
      'last_episode_to_air': aired.isEmpty ? null : aired.last,
      'next_episode_to_air': upcoming.isEmpty ? null : upcoming.first,
      'seasons': [
        for (var s = 1; s <= m.seasons.length; s++)
          season(m, s)..remove('episodes'),
      ],
    });
    return data;
  }

  Map<String, dynamic> credits(DemoMedia m) => {
    'id': m.id,
    'cast': [
      for (final (i, (personId, character)) in m.cast.indexed)
        {
          'id': personId,
          'name': demoPerson(personId).name,
          'character': character,
          'profile_path': '/demo/person/$personId.png',
          'order': i,
          'known_for_department': 'Acting',
        },
    ],
    'crew': [
      if (m.director != null)
        {
          'id': 900000 + m.id,
          'name': m.director,
          'job': 'Director',
          'department': 'Directing',
        },
    ],
  };

  List<Map<String, dynamic>> related(DemoMedia m) {
    final others =
        demoCatalog
            .where((o) => o.id != m.id && o.isTv == m.isTv)
            .map((o) => (o, o.genres.where(m.genres.contains).length))
            .where((p) => p.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (o, _) in others.take(8)) summary(o)];
  }

  Map<String, dynamic> watchProviders(DemoMedia m) {
    // Illustrative only: availability differs by country and changes often.
    final provider = m.isTv
        ? {
            'provider_id': 8,
            'provider_name': 'Netflix',
            'logo_path': '/demo/logo/netflix.png',
          }
        : {
            'provider_id': 337,
            'provider_name': 'Disney Plus',
            'logo_path': '/demo/logo/disney.png',
          };
    return {
      'id': m.id,
      'results': {
        'FR': {
          'link': '',
          'flatrate': [
            provider,
            {
              'provider_id': 119,
              'provider_name': 'Amazon Prime Video',
              'logo_path': '/demo/logo/prime.png',
            },
          ],
        },
      },
    };
  }

  Map<String, dynamic> person(DemoPerson p) => {
    'id': p.id,
    'name': p.name,
    'birthday': p.birthday,
    'place_of_birth': p.placeOfBirth,
    'profile_path': '/demo/person/${p.id}.png',
    'biography': language == 'fr'
        ? '${p.name} est une personnalité du cinéma née le ${p.birthday} '
              '(${p.placeOfBirth}). Biographie fictive, générée pour la '
              'démonstration.'
        : '${p.name} is a screen performer born on ${p.birthday} '
              '(${p.placeOfBirth}). Placeholder biography written for the demo.',
    'known_for_department': 'Acting',
  };

  Map<String, dynamic> combinedCredits(DemoPerson p) => {
    'id': p.id,
    'cast': [
      for (final m in demoCatalog)
        for (final (personId, character) in m.cast)
          if (personId == p.id) {...summary(m), 'character': character},
    ],
  };

  List<DemoMedia> _byType(String type) =>
      demoCatalog.where((m) => m.mediaType == type).toList();

  Map<String, dynamic> _page(List<Map<String, dynamic>> results) => {
    'page': 1,
    'results': results,
    'total_pages': 1,
    'total_results': results.length,
  };

  /// TMDB-shaped body for [uri], or `null` (404) for an unknown resource.
  Object? respond(Uri uri) {
    final seg = uri.pathSegments.skipWhile((s) => s != '3').skip(1).toList();
    if (seg.isEmpty) return null;
    final q = uri.queryParameters;

    switch (seg) {
      case ['authentication']:
        return {'success': true, 'status_code': 1};
      case ['search', final type]:
        final query = (q['query'] ?? '').toLowerCase();
        return _page([
          for (final m in _byType(type == 'multi' ? 'movie' : type))
            if (m.titleFr.toLowerCase().contains(query) ||
                m.titleEn.toLowerCase().contains(query) ||
                m.originalTitle.toLowerCase().contains(query))
              summary(m),
        ]);
      case ['discover', final type]:
        if (q['page'] != null && q['page'] != '1') return _page([]);
        final genres = q['with_genres']?.split(',').map(int.parse).toSet();
        final minRating = double.tryParse(q['vote_average.gte'] ?? '');
        final list =
            _byType(type)
                .where((m) => genres == null || m.genres.any(genres.contains))
                .where((m) => minRating == null || m.rating >= minRating)
                .toList()
              ..sort((a, b) => b.popularity.compareTo(a.popularity));
        return _page([for (final m in list) summary(m)]);
      case ['person', final id]:
        final p = demoPeople.where((p) => p.id == int.tryParse(id));
        return p.isEmpty ? null : person(p.first);
      case ['person', final id, 'combined_credits']:
        final p = demoPeople.where((p) => p.id == int.tryParse(id));
        return p.isEmpty ? null : combinedCredits(p.first);
      case ['collection', final id]:
        final parts = demoCatalog.where(
          (m) => m.collection?.$1 == int.tryParse(id),
        );
        if (parts.isEmpty) return null;
        return {
          'id': int.parse(id),
          'name': parts.first.collection!.$2,
          'parts': [for (final m in parts) summary(m)],
        };
      case ['tv', final id, 'season', final n]:
        final m = demoMedia('tv', int.tryParse(id) ?? -1);
        final s = int.tryParse(n) ?? 0;
        if (m == null || s < 1 || s > m.seasons.length) return null;
        return season(m, s);
      case [final type, final id, ...final rest]
          when type == 'movie' || type == 'tv':
        final m = demoMedia(type, int.tryParse(id) ?? -1);
        if (m == null) return null;
        switch (rest) {
          case []:
            final data = details(m);
            for (final part in (q['append_to_response'] ?? '').split(',')) {
              final value = switch (part) {
                'credits' => credits(m),
                'similar' => _page(related(m)),
                'recommendations' => _page(related(m).reversed.toList()),
                'watch/providers' => watchProviders(m),
                'videos' => {'id': m.id, 'results': <Object>[]},
                _ when part.startsWith('season/') => () {
                  final s = int.tryParse(part.substring(7)) ?? 0;
                  return s >= 1 && s <= m.seasons.length ? season(m, s) : null;
                }(),
                _ => null,
              };
              if (value != null) data[part] = value;
            }
            return data;
          case ['credits']:
            return credits(m);
          case ['similar']:
            return _page(related(m));
          case ['recommendations']:
            return _page(related(m).reversed.toList());
          case ['watch', 'providers']:
            return watchProviders(m);
          case ['videos']:
            return {'id': m.id, 'results': <Object>[]};
        }
        return null;
    }
    return null;
  }
}

/// Resolves TMDB API calls locally with [DemoTmdb]; other requests fail.
class DemoTmdbInterceptor extends Interceptor {
  DemoTmdbInterceptor(this.tmdb);

  final DemoTmdb tmdb;

  /// Requests answered so far, for diagnostics.
  final List<Uri> requests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    requests.add(uri);
    final body = uri.host == 'api.themoviedb.org' ? tmdb.respond(uri) : null;
    if (body == null) {
      handler.reject(
        DioException.badResponse(
          statusCode: 404,
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
        ),
      );
      return;
    }
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: body),
    );
  }
}
