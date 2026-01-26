import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => mockRepository.getSeenItems(),
    ).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepository.getLikedEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);
  });

  test(
    'importList creates list and adds entries, ignoring invalid entries',
    () async {
      final added = <MediaItem>[];

      when(() => mockRepository.createList(any())).thenAnswer((_) async {});
      when(() => mockRepository.addToList(any(), any())).thenAnswer((
        inv,
      ) async {
        final item = inv.positionalArguments[0] as MediaItem;
        added.add(item);
      });

      final provider = SearchProvider(mockRepository);

      await provider.importList('mylist', ['123:movie', '456:tv', 'bad_entry']);

      // createList should have been called (mock verifies no throw)
      // addToList should have been called twice
      expect(added.length, equals(2));
      expect(added.map((e) => e.id).toSet(), equals({123, 456}));
    },
  );
}
