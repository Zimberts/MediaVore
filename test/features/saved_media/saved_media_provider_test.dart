import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

import '../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
  });

  late MockMediaRepository mockRepository;
  late SearchProvider provider;

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

    provider = SearchProvider(mockRepository);
  });

  test('createList calls repository and updates listNames', () async {
    when(
      () => mockRepository.createList('newlist'),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'newlist']);

    await provider.createList('newlist');

    expect(provider.listNames.contains('newlist'), isTrue);
    verify(() => mockRepository.createList('newlist')).called(1);
  });

  test('importList creates list and adds entries', () async {
    when(
      () => mockRepository.createList('imported'),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.addToList(any(), 'imported'),
    ).thenAnswer((_) async => {});
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'imported']);

    final entries = ['10:movie', '20:tv'];
    await provider.importList('imported', entries);

    expect(provider.listNames.contains('imported'), isTrue);
    verify(() => mockRepository.createList('imported')).called(1);
    verify(() => mockRepository.addToList(any(), 'imported')).called(2);
  });
}
