import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_tmdb.dart';

void main() {
  late FakeTmdb tmdb;
  late Dio dio;

  setUp(() {
    tmdb = FakeTmdb();
    dio = Dio()..httpClientAdapter = tmdb;
  });

  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final response = await dio.get<Map<String, dynamic>>(
      'https://api.themoviedb.org/3/$path',
      queryParameters: query,
    );
    return response.data!;
  }

  group('FakeTmdb', () {
    test('should answer a movie with the requested id and appends', () async {
      final movie = await get('movie/550', {
        'append_to_response': 'credits,videos',
      });

      expect(movie['id'], 550);
      expect(movie['title'], 'Movie 550');
      expect(movie['credits'], isA<Map<String, dynamic>>());
      expect(movie['videos'], isA<Map<String, dynamic>>());
      expect(tmdb.byKind, {'movie+2': 1});
    });

    test('should answer a show with its seasons and a season with its '
        'episodes', () async {
      final show = await get('tv/42');
      final season = await get('tv/42/season/2');

      expect(show['seasons'], hasLength(2));
      expect(season['season_number'], 2);
      expect(season['episodes'], hasLength(10));
    });

    test('should shift ids between pages so that pages never repeat', () async {
      final first = await get('discover/movie', {'page': 1});
      final second = await get('discover/movie', {'page': 2});

      Set<int> ids(Map<String, dynamic> page) => {
        for (final item in page['results'] as List)
          (item as Map<String, dynamic>)['id'] as int,
      };
      expect(ids(first).intersection(ids(second)), isEmpty);
      expect(second['page'], 2);
    });

    test('should answer an override instead of the fixture', () async {
      tmdb.respond('movie/1', {'id': 1, 'title': 'Custom'});

      expect((await get('movie/1'))['title'], 'Custom');
    });

    test('should record and fail a request no route covers', () async {
      await expectLater(get('unknown/route'), throwsA(isA<DioException>()));
      await expectLater(
        dio.get<Object>('https://image.tmdb.org/t/p/w500/x.jpg'),
        throwsA(isA<DioException>()),
      );

      expect(tmdb.unhandled, hasLength(2));
      expect(tmdb.requestCount, 2);
    });

    for (final (failure, status) in [
      (FakeTmdbFailure.unauthorized, 401),
      (FakeTmdbFailure.rateLimited, 429),
      (FakeTmdbFailure.serverError, 500),
    ]) {
      test('should answer $status when switched to ${failure.name}', () async {
        tmdb.fail(failure);

        await expectLater(
          get('movie/1'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              status,
            ),
          ),
        );
      });
    }

    test('should time out and go offline when switched to', () async {
      tmdb.fail(FakeTmdbFailure.timeout);
      await expectLater(
        get('movie/1'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionTimeout,
          ),
        ),
      );

      tmdb.fail(FakeTmdbFailure.offline);
      await expectLater(
        get('movie/1'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });

    test('should fail only the matching paths, then recover', () async {
      tmdb.fail(FakeTmdbFailure.serverError, pathPrefix: 'tv/');

      expect((await get('movie/1'))['id'], 1);
      await expectLater(get('tv/1'), throwsA(isA<DioException>()));

      tmdb.recover();
      expect((await get('tv/1'))['id'], 1);
      expect(tmdb.countFor('tv/'), 2);
    });
  });
}
