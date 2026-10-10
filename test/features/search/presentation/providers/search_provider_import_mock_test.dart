import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart'
    as repo_types;

typedef ImportProgress = void Function(double progress, String status);

class MockRepo extends Mock implements MediaRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImportMode.append);
    registerFallbackValue((double progress, String status) {});
  });

  late MockRepo mock;
  late SearchProvider provider;

  setUp(() {
    mock = MockRepo();

    // stub methods used by provider after import
    when(() => mock.getSeenItems()).thenAnswer((_) async => <SeenItem>[]);
    when(() => mock.getLikedEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mock.getNotifiedItems(),
    ).thenAnswer((_) async => <repo_types.NotifiedItem>[]);
    when(
      () => mock.getQuickAddItems(),
    ).thenAnswer((_) async => <repo_types.QuickAddItem>[]);
    when(() => mock.getWatchlistEntries()).thenAnswer((_) async => <String>[]);
    when(
      () => mock.getAllListNames(),
    ).thenAnswer((_) async => <String>['watchlist']);
    when(() => mock.getListEntries(any())).thenAnswer((_) async => <String>[]);
    when(
      () => mock.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => <repo_types.MediaItemPreview>[]);
    when(() => mock.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mock.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mock.watchNotifiedItems()).thenAnswer((_) => const Stream.empty());

    provider = SearchProvider(mock);
  });

  test('provider.importAllData calls repository and updates status', () async {
    when(
      () => mock.importAllData(
        any(),
        mode: any(named: 'mode'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async {});

    final envelope = <int>[1, 2, 3];

    await provider.importAllData(envelope, mode: ImportMode.merge);

    verify(
      () => mock.importAllData(
        any(),
        mode: ImportMode.merge,
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1);
    expect(provider.importProgress, 1.0);
    expect(provider.importStatus, 'Done!');
  });

  test('provider.importAllData handles repository exception', () async {
    when(
      () => mock.importAllData(
        any(),
        mode: any(named: 'mode'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenThrow(Exception('boom'));

    final envelope = <int>[1, 2, 3];

    await provider.importAllData(envelope, mode: ImportMode.append);

    expect(provider.importStatus.startsWith('Error'), true);
  });
}
