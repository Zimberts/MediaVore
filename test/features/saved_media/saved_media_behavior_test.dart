import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
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
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(
      () => mockRepo.getWatchlistEntries(),
    ).thenAnswer((_) async => <String>[]);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mockRepo.getNotifiedItems(),
    ).thenAnswer((_) async => <NotifiedItem>[]);

    when(() => mockRepo.createList(any())).thenAnswer((_) async {});
    when(() => mockRepo.deleteList(any())).thenAnswer((_) async {});
    when(
      () => mockRepo.getListPreviews(any()),
    ).thenAnswer((_) async => <MediaItemPreview>[]);
    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
  });

  test('createList and deleteList update provider list names', () async {
    final provider = SearchProvider(mockRepo);
    await Future.delayed(Duration.zero);

    final before = provider.listNames;
    expect(before, contains('watchlist'));

    await provider.createList('mylist');
    expect(provider.listNames, isA<List<String>>());

    await provider.deleteList('mylist');
    expect(provider.listNames, isA<List<String>>());
  });
}
