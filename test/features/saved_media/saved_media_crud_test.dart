import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    when(() => mockRepository.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getListPreviews(any(), limit: any(named: 'limit'))).thenAnswer((_) async => <MediaItemPreview>[]);
    when(() => mockRepository.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepository.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepository.getSeenStatus(any(), any())).thenAnswer((_) async => <SeenItem>[]);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => <NotifiedItem>[]);
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async => {});

    provider = SearchProvider(mockRepository);
  });

  test('Create and delete list flows update provider state and call repository', () async {
    when(() => mockRepository.createList('MyList')).thenAnswer((_) async => {});
    when(() => mockRepository.deleteList('MyList')).thenAnswer((_) async => {});

    // After creating, repository should return the new list name
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', 'MyList']);
    await provider.createList('MyList');
    verify(() => mockRepository.createList('MyList')).called(1);
    expect(provider.listNames.contains('MyList'), isTrue);

    // After deletion, repository returns original names
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist']);
    await provider.deleteList('MyList');
    verify(() => mockRepository.deleteList('MyList')).called(1);
    expect(provider.listNames.contains('MyList'), isFalse);
  });

  test('Share link generation and import list', () async {
    when(() => mockRepository.createList('Shared')).thenAnswer((_) async => {});
    when(() => mockRepository.addToList(any(), 'Shared')).thenAnswer((_) async => {});

    // Simulate repository returning the new list after import
    when(() => mockRepository.getAllListNames()).thenAnswer((_) async => ['watchlist', 'Shared']);

    final entries = ['42:movie', '43:tv'];
    // Ensure getListEntries returns the entries for the newly created list so share link is generated
    when(() => mockRepository.getListEntries('Shared')).thenAnswer((_) async => entries);

    await provider.importList('Shared', entries);

    expect(provider.listNames.contains('Shared'), isTrue);
    final link = provider.getShareLinkForList('Shared');
    expect(link, contains('mediavore.app/share'));
  });
}
