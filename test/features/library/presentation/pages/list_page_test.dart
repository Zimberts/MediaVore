import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/library/presentation/pages/list_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepo;
  late MockSharedPreferences mockPrefs;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    mockRepo = MockMediaRepository();
    mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getStringList(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);

    when(
      () => mockRepo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'custom_list']);
    when(() => mockRepo.getWatchlistEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepo.getSeenItems()).thenAnswer((_) async => []);
    when(() => mockRepo.getListEntries(any())).thenAnswer((_) async => []);
    when(
      () => mockRepo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => mockRepo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => mockRepo.getNotifiedItems()).thenAnswer((_) async => []);
    when(
      () => mockRepo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());

    searchProvider = SearchProvider(mockRepo);
    settingsProvider = SettingsProvider(mockPrefs, FakeTmdbCredentialStore());
  });

  Widget buildTestWidget({
    String initialList = 'watchlist',
    GlobalKey<ListPageState>? key,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        theme: AppPalette.paper.toThemeData(),
        home: Scaffold(
          body: ListPage(key: key, initialList: initialList),
        ),
      ),
    );
  }

  group('ListPage', () {
    testWidgets(
      'shows empty state with "Remplir en swipant" button switching to discover tab',
      (tester) async {
        when(
          () => mockRepo.getListEntries('watchlist'),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Remplir en swipant'), findsOneWidget);

        await tester.tap(find.text('Remplir en swipant'));
        await tester.pumpAndSettle();

        expect(searchProvider.selectedTab, AppTab.discover);
      },
    );

    testWidgets(
      'sort sheet opens and allows toggling sort method and reverse switch',
      (tester) async {
        when(
          () => mockRepo.getListEntries('watchlist'),
        ).thenAnswer((_) async => ['1:movie', '2:movie']);
        when(
          () => mockRepo.getMediaDetails(1, type: MediaType.movie),
        ).thenAnswer(
          (_) async => MediaDetails(
            item: const MediaItem(
              id: 1,
              title: 'Alpha',
              overview: '',
              releaseDate: '2020',
              mediaType: MediaType.movie,
            ),
            cast: [],
          ),
        );
        when(
          () => mockRepo.getMediaDetails(2, type: MediaType.movie),
        ).thenAnswer(
          (_) async => MediaDetails(
            item: const MediaItem(
              id: 2,
              title: 'Beta',
              overview: '',
              releaseDate: '2022',
              mediaType: MediaType.movie,
            ),
            cast: [],
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap sort button
        await tester.tap(find.byIcon(Icons.swap_vert));
        await tester.pumpAndSettle();

        // Sort sheet is shown
        expect(find.text('Options de tri'), findsOneWidget);
        expect(find.text('Ordre manuel'), findsOneWidget);
        expect(find.text('Date de sortie'), findsOneWidget);
        expect(find.text('Aléatoire'), findsOneWidget);
        expect(find.text('Ordre inversé'), findsOneWidget);

        // Tap on Date de sortie
        await tester.tap(find.text('Date de sortie'));
        await tester.pumpAndSettle();

        // Switch reverse order
        await tester.tap(find.byIcon(Icons.swap_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.byType(Switch), findsOneWidget);
      },
    );

    testWidgets(
      'display mode sheet opens and allows selecting grid columns or detailed list',
      (tester) async {
        when(
          () => mockRepo.getListEntries('watchlist'),
        ).thenAnswer((_) async => ['1:movie']);
        when(
          () => mockRepo.getMediaDetails(1, type: MediaType.movie),
        ).thenAnswer(
          (_) async => MediaDetails(
            item: const MediaItem(
              id: 1,
              title: 'Alpha',
              overview: '',
              releaseDate: '2020',
              mediaType: MediaType.movie,
            ),
            cast: [],
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap display mode button
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();

        // Sheet displays choices: Grille (2 colonnes), Grille (3 colonnes), Grille (4 colonnes), Liste détaillée
        expect(find.text('Options d\'affichage'), findsOneWidget);
        expect(find.text('Grille (2 colonnes)'), findsOneWidget);
        expect(find.text('Grille (3 colonnes)'), findsOneWidget);
        expect(find.text('Grille (4 colonnes)'), findsOneWidget);
        expect(find.text('Liste détaillée'), findsOneWidget);

        // Select 3 colonnes
        await tester.tap(find.text('Grille (3 colonnes)'));
        await tester.pumpAndSettle();

        expect(settingsProvider.gridSize, 3.0);
        expect(settingsProvider.displayMode, DisplayMode.grid);

        // Open sheet again and select Liste détaillée
        await tester.tap(find.byIcon(Icons.grid_view));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Liste détaillée'));
        await tester.pumpAndSettle();

        expect(settingsProvider.displayMode, DisplayMode.list);
      },
    );

    testWidgets('selection mode: select all, deselect all, and cancel exit', (
      tester,
    ) async {
      final items = [
        const MediaItem(
          id: 1,
          title: 'Item 1',
          overview: '',
          releaseDate: '2020',
          mediaType: MediaType.movie,
        ),
        const MediaItem(
          id: 2,
          title: 'Item 2',
          overview: '',
          releaseDate: '2021',
          mediaType: MediaType.movie,
        ),
      ];
      when(
        () => mockRepo.getListEntries('watchlist'),
      ).thenAnswer((_) async => ['1:movie', '2:movie']);
      when(
        () => mockRepo.getMediaDetails(1, type: MediaType.movie),
      ).thenAnswer((_) async => MediaDetails(item: items[0], cast: []));
      when(
        () => mockRepo.getMediaDetails(2, type: MediaType.movie),
      ).thenAnswer((_) async => MediaDetails(item: items[1], cast: []));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter selection mode via more actions
      await tester.tap(find.byKey(const Key('lists_more_actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sélectionner'));
      await tester.pumpAndSettle();

      // In selection mode: app bar displays count and Tout / Rien buttons
      expect(find.text('0 sélectionné'), findsOneWidget);
      expect(find.text('Tout'), findsOneWidget);

      // Tap Tout -> both selected
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();
      expect(find.text('2 sélectionnés'), findsOneWidget);
      expect(find.text('Aucun'), findsOneWidget);

      // Tap Aucun -> none selected
      await tester.tap(find.text('Aucun'));
      await tester.pumpAndSettle();
      expect(find.text('0 sélectionné'), findsOneWidget);

      // Close selection mode
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Tout'), findsNothing);
    });

    testWidgets('selection mode: removing items updates list immediately', (
      tester,
    ) async {
      final items = [
        const MediaItem(
          id: 1,
          title: 'Item 1',
          overview: '',
          releaseDate: '2020',
          mediaType: MediaType.movie,
        ),
        const MediaItem(
          id: 2,
          title: 'Item 2',
          overview: '',
          releaseDate: '2021',
          mediaType: MediaType.movie,
        ),
      ];
      when(
        () => mockRepo.getListEntries('watchlist'),
      ).thenAnswer((_) async => ['1:movie', '2:movie']);
      when(
        () => mockRepo.getWatchlistEntries(),
      ).thenAnswer((_) async => ['1:movie', '2:movie']);
      when(
        () => mockRepo.getMediaDetails(1, type: MediaType.movie),
      ).thenAnswer((_) async => MediaDetails(item: items[0], cast: []));
      when(
        () => mockRepo.getMediaDetails(2, type: MediaType.movie),
      ).thenAnswer((_) async => MediaDetails(item: items[1], cast: []));
      when(
        () => mockRepo.removeFromList(any(), any(), any()),
      ).thenAnswer((_) async => {});
      await searchProvider.loadWatchlist();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.tap(find.byKey(const Key('lists_more_actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sélectionner'));
      await tester.pumpAndSettle();

      // Tap Tout
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();

      // Tap Delete in app bar
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Items removed from repository immediately
      verify(
        () => mockRepo.removeFromList(1, MediaType.movie, 'watchlist'),
      ).called(1);
      verify(
        () => mockRepo.removeFromList(2, MediaType.movie, 'watchlist'),
      ).called(1);
    });

    testWidgets('ensures tap targets meet minimum 48x48 dp standard', (
      tester,
    ) async {
      when(
        () => mockRepo.getListEntries('watchlist'),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final tapTargets = find.byType(AppTapTarget);
      expect(tapTargets, findsWidgets);
      for (final element in tapTargets.evaluate()) {
        final renderBox = element.renderObject as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
          expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
        }
      }
    });
  });
}
