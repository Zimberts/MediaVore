import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import '../../helpers/mocks.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();

    // Basic stubs required by provider init
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => []);

    provider = SearchProvider(mockRepository);
  });

  group('Cache fill & prefetch', () {
    test(
      'fillCache triggers repository.fillCache and toggles loading flag',
      () async {
        final completer = Completer<void>();

        when(
          () => mockRepository.fillCache(),
        ).thenAnswer((_) => completer.future);
        when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 123);

        final future = provider.fillCache();

        // While fillCache hasn't completed, provider should report cache loading
        expect(provider.isCacheLoading, isTrue);

        // Complete the mocked fill operation
        completer.complete();
        await future;

        // After completion, provider should have updated cache size and cleared loading
        expect(provider.isCacheLoading, isFalse);
        expect(provider.cacheSize, equals(123));
      },
    );

    test('fillCache handles immediate completion', () async {
      when(
        () => mockRepository.fillCache(),
      ).thenAnswer((_) async => Future.value());
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);

      await provider.fillCache();

      expect(provider.isCacheLoading, isFalse);
    });
  });
}
