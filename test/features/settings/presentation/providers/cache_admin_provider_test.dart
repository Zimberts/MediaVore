import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/settings/presentation/providers/cache_admin_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late CacheAdminProvider provider;

  setUp(() {
    mockRepository = MockMediaRepository();
    when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 1024);
    when(() => mockRepository.getSeenDbSize()).thenAnswer((_) async => 2048);
    when(
      () => mockRepository.clearCache(complete: any(named: 'complete')),
    ).thenAnswer((_) async {});
    when(() => mockRepository.fillCache()).thenAnswer((_) async {});
    when(
      () => mockRepository.exportAllData(),
    ).thenAnswer((_) async => [1, 2, 3]);

    provider = CacheAdminProvider(mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('CacheAdminProvider', () {
    test('initializes cache and db sizes', () async {
      await provider.init();

      expect(provider.cacheSize, 1024);
      expect(provider.seenDbSize, 2048);
    });

    test('clearCache updates cache size and manages loading state', () async {
      await provider.init();
      when(() => mockRepository.getCacheSize()).thenAnswer((_) async => 0);

      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isCacheLoading));

      await provider.clearCache(complete: true);

      expect(loadingStates, contains(true));
      expect(provider.isCacheLoading, isFalse);
      expect(provider.cacheSize, 0);
      verify(() => mockRepository.clearCache(complete: true)).called(1);
    });

    test('exportAllData delegates to repository', () async {
      final data = await provider.exportAllData();
      expect(data, [1, 2, 3]);
      verify(() => mockRepository.exportAllData()).called(1);
    });
  });
}
