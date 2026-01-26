import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(FakeMediaItem());
    registerFallbackValue(FakeSeenItem());
  });

  setUp(() {
    mockRepository = MockMediaRepository();
  });

  testWidgets(
    'Tapping mark-as-seen in Releases shows snackbar and calls repo',
    (tester) async {
      final now = DateTime.now();

      final notified = [
        NotifiedItem(
          tmdbId: 500,
          type: MediaType.movie,
          title: 'Notified Movie',
          posterPath: null,
          releaseDate: now.subtract(const Duration(days: 1)),
          autoNotify: false,
        ),
      ];

      final seenList = <SeenItem>[];

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
        () => mockRepository.getLikedEntries(),
      ).thenAnswer((_) async => <String>[]);

      when(
        () => mockRepository.getNotifiedItems(),
      ).thenAnswer((_) async => notified);

      when(
        () => mockRepository.getSeenItems(),
      ).thenAnswer((_) async => seenList);

      when(() => mockRepository.markAsSeen(any())).thenAnswer((inv) async {
        final s = inv.positionalArguments[0] as SeenItem;
        seenList.add(s);
      });

      when(
        () => mockRepository.getMediaDetails(any(), type: any(named: 'type')),
      ).thenAnswer(
        (_) async => MediaDetails(
          item: MediaItem(
            id: 500,
            title: 'Notified Movie',
            overview: '',
            releaseDate: '',
            mediaType: MediaType.movie,
          ),
          cast: [],
        ),
      );
      when(
        () => mockRepository.getNotifiedItems(),
      ).thenAnswer((_) async => notified);

      final mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getInt(any())).thenReturn(0);
      when(() => mockPrefs.getDouble(any())).thenReturn(3.0);
      when(() => mockPrefs.getBool(any())).thenReturn(false);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      final settings = SettingsProvider(mockPrefs);
      final provider = SearchProvider(mockRepository);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<SearchProvider>.value(value: provider),
          ],
          child: MaterialApp(
            theme: DefaultLightPalette().toThemeData(),
            home: const NotificationCenterPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Releases tab is first; find the visibility icon and tap it
      final markSeen = find.byIcon(Icons.visibility_outlined);
      expect(markSeen, findsOneWidget);

      await tester.tap(markSeen);
      await tester.pumpAndSettle();

      // Expect snackbar with the title
      expect(find.text('Marked Notified Movie as seen'), findsOneWidget);

      // Ensure repository.markAsSeen was called
      verify(
        () => mockRepository.markAsSeen(any()),
      ).called(greaterThanOrEqualTo(1));
    },
  );
}
