import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockCredentialStore extends Mock implements TmdbCredentialStore {}

class _MockLocaleService extends Mock implements LocaleService {}

void main() {
  late _MockDio dio;
  late MediaRemoteDataSource remote;

  setUp(() {
    dio = _MockDio();
    final credentials = _MockCredentialStore();
    when(() => credentials.credential).thenReturn('test-key');
    final locale = _MockLocaleService();
    remote = MediaRemoteDataSource(
      dio: dio,
      credentials: credentials,
      locale: locale,
    );
  });

  group('MediaRemoteDataSource manual media guard', () {
    test('should throw InvalidMediaIdException for negative IDs', () async {
      await expectLater(
        () => remote.getMediaItem(-1),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getMediaDetailsBundle(-1),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getSeasonsDetails(-1, [1]),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getSeasonDetails(-1, 1),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getMediaCredits(-1),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getSimilarMedia(-1, MediaType.movie),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getRecommendedMedia(-1, MediaType.tv),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getWatchProviders(-1, MediaType.movie),
        throwsA(isA<InvalidMediaIdException>()),
      );
      await expectLater(
        () => remote.getVideos(-1, MediaType.movie),
        throwsA(isA<InvalidMediaIdException>()),
      );
      verifyZeroInteractions(dio);
    });
  });
}
