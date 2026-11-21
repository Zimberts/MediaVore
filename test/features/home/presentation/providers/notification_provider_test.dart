import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/home/presentation/providers/notification_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late NotificationProvider provider;

  final tNotified = NotifiedItem(
    tmdbId: 201,
    title: 'Stranger Things',
    posterPath: '/stranger.jpg',
    type: MediaType.tv,
    autoNotify: true,
  );

  const tSeries = MediaItem(
    id: 201,
    title: 'Stranger Things',
    overview: 'Upside Down',
    releaseDate: '2016-07-15',
    mediaType: MediaType.tv,
  );

  setUpAll(() {
    registerFallbackValue(tSeries);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getNotifiedItems(),
    ).thenAnswer((_) async => [tNotified]);
    when(
      () => mockRepository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.toggleNotification(any()),
    ).thenAnswer((_) async {});
    when(() => mockRepository.refreshNotifiedItems()).thenAnswer((_) async {});

    provider = NotificationProvider(mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('NotificationProvider', () {
    test('initializes and checks isNotified correctly', () async {
      await provider.init();

      expect(provider.notifiedItems.length, 1);
      expect(provider.isNotified(tSeries), isTrue);
    });

    test('toggleNotification updates notified state', () async {
      await provider.init();
      when(() => mockRepository.getNotifiedItems()).thenAnswer((_) async => []);

      await provider.toggleNotification(tSeries);

      verify(() => mockRepository.toggleNotification(tSeries)).called(1);
      expect(provider.isNotified(tSeries), isFalse);
    });

    test('refreshNotifiedItems toggles isNotifiedRefreshing state', () async {
      await provider.init();

      final states = <bool>[];
      provider.addListener(() => states.add(provider.isNotifiedRefreshing));

      await provider.refreshNotifiedItems();

      expect(states, contains(true));
      expect(provider.isNotifiedRefreshing, isFalse);
      verify(() => mockRepository.refreshNotifiedItems()).called(1);
    });
  });
}
