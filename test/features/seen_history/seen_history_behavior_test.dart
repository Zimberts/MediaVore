import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepo = MockMediaRepository();
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepo.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getListPreviews(any()),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
  });

  test('loadAllSeenStatus populates seenItems and seenCounts', () async {
    final now = DateTime.now();
    final movie1 = SeenItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'M1',
      seenDate: now,
    );
    final movie1b = SeenItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'M1',
      seenDate: now.subtract(Duration(days: 1)),
    );

    final tv1 = SeenItem(
      tmdbId: 2,
      type: MediaType.tv,
      title: 'T1',
      seenDate: now,
      seasonNumber: 1,
      episodeNumber: 1,
    );
    final tv1dup = SeenItem(
      tmdbId: 2,
      type: MediaType.tv,
      title: 'T1',
      seenDate: now.subtract(Duration(days: 2)),
      seasonNumber: 1,
      episodeNumber: 1,
    );

    when(
      () => mockRepo.getSeenItems(),
    ).thenAnswer((_) async => [movie1, movie1b, tv1, tv1dup]);

    final provider = SearchProvider(mockRepo);
    await Future.delayed(Duration.zero);

    expect(provider.seenItems.length, 4);

    final movieMediaItem = MediaItem(
      id: 1,
      title: 'M1',
      overview: '',
      releaseDate: '2020-01-01',
    );
    expect(provider.getSeenCount(movieMediaItem), 2);

    final tvMediaItem = MediaItem(
      id: 2,
      title: 'T1',
      overview: '',
      releaseDate: '2020-01-01',
      mediaType: MediaType.tv,
    );
    expect(provider.getSeenCount(tvMediaItem), 1);
  });
}
