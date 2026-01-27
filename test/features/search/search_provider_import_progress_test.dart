import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
    registerFallbackValue(ImportMode.append);
  });
  group('SearchProvider import progress', () {
    late MockMediaRepository mockRepository;
    late SearchProvider provider;

    setUp(() {
      mockRepository = MockMediaRepository();

      // Stubs used by SearchProvider._init
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
      when(() => mockRepository.createList(any())).thenAnswer((_) async {});
      when(
        () => mockRepository.addToList(any(), any()),
      ).thenAnswer((_) async {});

      provider = SearchProvider(mockRepository);
    });

    test('importSeenData updates progress and status', () async {
      // Prepare repository.importSeenData to call onProgress inside
      when(
        () => mockRepository.importSeenData(
          any(),
          mode: any(named: 'mode'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((inv) async {
        final onProgress =
            inv.namedArguments[#onProgress] as Function(double, String)?;
        if (onProgress != null) {
          onProgress(0.25, 'quarter');
          onProgress(0.5, 'half');
          onProgress(1.0, 'done');
        }
      });

      final data = [
        {
          'tmdbId': 1,
          'type': 'movie',
          'title': 'A',
          'seenDate': DateTime.now().toIso8601String(),
        },
      ];

      await provider.importSeenData(data);

      expect(provider.importProgress, 1.0);
      expect(provider.importStatus.toLowerCase(), contains('done'));
    });
  });
}
