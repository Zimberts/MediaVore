import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/library/presentation/pages/library_page.dart';
import 'package:mediavore/features/library/presentation/widgets/list_dialogs.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  late MockMediaRepository repository;
  late MockSharedPreferences preferences;
  late SearchProvider searchProvider;
  late SettingsProvider settingsProvider;

  /// Lists of the fake repository, mutated like the real one.
  late Map<String, List<String>> lists;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() {
    repository = MockMediaRepository();
    preferences = MockSharedPreferences();
    lists = {
      'Weekend': ['10:tv', '11:tv'],
      'watchlist': ['1:movie', '2:movie', '3:tv', '4:movie', '5:tv', '6:tv'],
    };

    when(() => preferences.getInt(any())).thenReturn(null);
    when(() => preferences.getDouble(any())).thenReturn(null);
    when(() => preferences.getBool(any())).thenReturn(null);

    when(
      () => repository.getAllListNames(),
    ).thenAnswer((_) async => lists.keys.toList());
    when(
      () => repository.getWatchlistEntries(),
    ).thenAnswer((_) async => lists['watchlist']!);
    when(() => repository.getListEntries(any())).thenAnswer(
      (invocation) async =>
          lists[invocation.positionalArguments.first as String] ?? [],
    );
    when(
      () => repository.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((invocation) async {
      final entries =
          lists[invocation.positionalArguments.first as String] ?? [];
      final limit = invocation.namedArguments[#limit] as int? ?? 4;
      return [
        for (final entry in entries.take(limit))
          MediaItemPreview(
            id: int.parse(entry.split(':').first),
            title: 'Title ${entry.split(':').first}',
            type: entry.split(':').last,
          ),
      ];
    });
    when(() => repository.getListMediaItems(any())).thenAnswer((_) async => []);
    when(() => repository.getSeenItems()).thenAnswer((_) async => []);
    when(() => repository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repository.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repository.getQuickAddItems()).thenAnswer((_) async => []);
    when(() => repository.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repository.getSeenDbSize()).thenAnswer((_) async => 0);
    when(
      () => repository.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => repository.createList(any())).thenAnswer((invocation) async {
      lists.putIfAbsent(
        invocation.positionalArguments.first as String,
        () => [],
      );
    });
    when(() => repository.addToList(any(), any())).thenAnswer((
      invocation,
    ) async {
      final item = invocation.positionalArguments[0] as MediaItem;
      final name = invocation.positionalArguments[1] as String;
      lists[name] = [...?lists[name], '${item.id}:${item.mediaType.name}'];
    });
    when(() => repository.removeFromList(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final id = invocation.positionalArguments[0] as int;
      final type = invocation.positionalArguments[1] as MediaType;
      final name = invocation.positionalArguments[2] as String;
      lists[name] = [...?lists[name]]..remove('$id:${type.name}');
    });
    when(
      () => repository.getMediaDetails(any(), type: any(named: 'type')),
    ).thenThrow(Exception('offline'));

    settingsProvider = SettingsProvider(preferences, FakeTmdbCredentialStore());
    locator.registerSingleton<MediaRepository>(repository);
  });

  tearDown(() async {
    await locator.reset();
  });

  Widget app({
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
    ListScannerBuilder? scannerBuilder,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: searchProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        theme: palette.toThemeData(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AppMessageHost(child: child!),
        home: Scaffold(body: LibraryPage(scannerBuilder: scannerBuilder)),
      ),
    );
  }

  /// Builds the provider inside the test zone, so that its start-up load
  /// completes while pumping.
  Future<void> pumpLibrary(
    WidgetTester tester, {
    AppPalette palette = AppPalette.paper,
    Locale locale = const Locale('en'),
    ListScannerBuilder? scannerBuilder,
  }) async {
    searchProvider = SearchProvider(repository);
    await tester.pumpWidget(
      app(palette: palette, locale: locale, scannerBuilder: scannerBuilder),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String name) => find.byKey(ValueKey('library_list_$name'));

  String rowLabel(WidgetTester tester, String name) =>
      tester.getSemantics(row(name)).label;

  group('lists overview', () {
    for (final palette in testPalettes) {
      testWidgets(
        'should list every list with its count (${palette.id.name})',
        (tester) async {
          await pumpLibrary(tester, palette: palette);

          expect(find.text('Library'), findsOneWidget);
          expect(find.text('Watchlist'), findsOneWidget);
          expect(find.text('Weekend'), findsOneWidget);
          expect(rowLabel(tester, 'watchlist'), contains('6 items'));
          expect(rowLabel(tester, 'watchlist'), contains('3 movies'));
          expect(rowLabel(tester, 'watchlist'), contains('3 series'));
          expect(rowLabel(tester, 'Weekend'), contains('2 items'));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('should show the watchlist first, translated', (tester) async {
      await pumpLibrary(tester, locale: const Locale('fr'));

      expect(find.text('À voir'), findsOneWidget);
      expect(find.text('watchlist'), findsNothing);
      expect(
        tester.getTopLeft(row('watchlist')).dy,
        lessThan(tester.getTopLeft(row('Weekend')).dy),
      );
    });

    testWidgets('should draw three mini posters and the films / series split', (
      tester,
    ) async {
      await pumpLibrary(tester);

      expect(
        find.descendant(
          of: row('watchlist'),
          matching: find.byType(MediaPosterCard),
        ),
        findsNWidgets(3),
      );
      final movie = find.descendant(
        of: row('watchlist'),
        matching: find.byKey(const Key('library_split_movie')),
      );
      final series = find.descendant(
        of: row('watchlist'),
        matching: find.byKey(const Key('library_split_series')),
      );
      expect(tester.getSize(movie).width, tester.getSize(series).width);
      expect(tester.getSize(movie).height, 4);
      // A list of series only has no movie share.
      expect(
        find.descendant(
          of: row('Weekend'),
          matching: find.byKey(const Key('library_split_movie')),
        ),
        findsNothing,
      );
    });

    testWidgets('should show an empty list with a count of zero', (
      tester,
    ) async {
      lists = {'watchlist': []};
      await pumpLibrary(tester);

      expect(rowLabel(tester, 'watchlist'), contains('no items'));
      expect(find.text('All · 0'), findsOneWidget);
      expect(find.byType(MediaPosterCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should open the tapped list', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(row('Weekend'));
      await tester.pumpAndSettle();

      final page = tester.widget<SavedMediaPage>(find.byType(SavedMediaPage));
      expect(page.initialList, 'Weekend');
      expect(page.typeFilter, isNull);
    });

    testWidgets('should keep 48 dp targets', (tester) async {
      await pumpLibrary(tester);

      for (final finder in [
        row('watchlist'),
        find.byKey(const Key('library_new_list')),
        find.byKey(const Key('library_import_list')),
      ]) {
        expect(
          tester.getSize(finder).height,
          greaterThanOrEqualTo(kMinTapTarget),
        );
      }
    });

    testWidgets(
      'should fit a long list name at text scale 2 on a 320 dp screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        lists['A very long list name that never seems to end, really'] = [
          '20:movie',
        ];

        await pumpLibrary(tester, locale: const Locale('fr'));

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('type filter', () {
    testWidgets('should show the exact count of each type', (tester) async {
      await pumpLibrary(tester);

      expect(find.text('All · 8'), findsOneWidget);
      expect(find.text('Movies · 3'), findsOneWidget);
      expect(find.text('TV Shows · 5'), findsOneWidget);
    });

    testWidgets('should restrict the counts and the mini posters', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Movies · 3'));
      await tester.pumpAndSettle();

      expect(rowLabel(tester, 'watchlist'), contains('3 items'));
      expect(rowLabel(tester, 'watchlist'), contains('no series'));
      expect(rowLabel(tester, 'Weekend'), contains('no items'));
      // The third film is the fourth entry: it is read beyond the cached
      // previews.
      final posters = tester
          .widgetList<MediaPosterCard>(
            find.descendant(
              of: row('watchlist'),
              matching: find.byType(MediaPosterCard),
            ),
          )
          .map((card) => card.data.title);
      expect(posters, ['Title 1', 'Title 2', 'Title 4']);
      expect(
        find.descendant(
          of: row('Weekend'),
          matching: find.byType(MediaPosterCard),
        ),
        findsNothing,
      );
    });

    testWidgets('should restrict the content of the opened list', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('TV Shows · 5'));
      await tester.pumpAndSettle();
      await tester.tap(row('watchlist'));
      await tester.pumpAndSettle();

      final page = tester.widget<SavedMediaPage>(find.byType(SavedMediaPage));
      expect(page.typeFilter, MediaType.tv);
      expect(find.text('Title 3'), findsOneWidget);
      expect(find.text('Title 5'), findsOneWidget);
      expect(find.text('Title 1'), findsNothing);
    });

    testWidgets('should update the counts after an addition and a removal', (
      tester,
    ) async {
      await pumpLibrary(tester);
      const film = MediaItem(
        id: 99,
        title: 'New',
        overview: '',
        releaseDate: '',
        mediaType: MediaType.movie,
      );

      await searchProvider.toggleInList(film, 'Weekend');
      await tester.pumpAndSettle();
      expect(find.text('All · 9'), findsOneWidget);
      expect(find.text('Movies · 4'), findsOneWidget);
      expect(rowLabel(tester, 'Weekend'), contains('3 items'));

      await searchProvider.removeFromList(film, 'Weekend');
      await tester.pumpAndSettle();
      expect(find.text('All · 8'), findsOneWidget);
      expect(find.text('Movies · 3'), findsOneWidget);
      expect(rowLabel(tester, 'Weekend'), contains('2 items'));
    });

    testWidgets('should be shared with the history', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Movies · 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(searchProvider.librarySection, LibrarySection.history);
      final history = tester.widget<SeenHistoryPage>(
        find.byType(SeenHistoryPage),
      );
      expect(history.typeFilter, MediaType.movie);
      expect(history.externalTypeFilter, isTrue);
    });
  });

  group('new list', () {
    testWidgets('should create a list from the name dialog', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('library_new_list')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Halloween ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      verify(() => repository.createList('Halloween')).called(1);
      expect(row('Halloween'), findsOneWidget);
      expect(rowLabel(tester, 'Halloween'), contains('no items'));
    });

    testWidgets('should not create a list without a name or when cancelled', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('library_new_list')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('library_new_list')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Later');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.createList(any()));
    });

    testWidgets('should refuse a name already in use', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('library_new_list')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'weekend');
      await tester.tap(find.text('Create'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verifyNever(() => repository.createList(any()));
      expect(
        find.text('A list named “weekend” already exists'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });
  });

  group('import', () {
    const link = 'https://mediavore.app/share?name=Shared&items=7:movie,8:tv';

    Future<void> confirmImport(WidgetTester tester) async {
      expect(find.text('Confirm Import'), findsOneWidget);
      expect(
        find.text('You are about to import a list with 2 items.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Shared'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => repository.createList('Shared')).called(1);
      verify(() => repository.addToList(any(), 'Shared')).called(2);
      expect(row('Shared'), findsOneWidget);
      expect(rowLabel(tester, 'Shared'), contains('2 items'));
      expect(find.text('All · 10'), findsOneWidget);
      expect(find.text('List “Shared” added'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    }

    testWidgets('should import a list from a link', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('library_import_list')));
      await tester.pumpAndSettle();
      expect(find.text('Import List'), findsOneWidget);
      await tester.tap(find.text('Import via Link'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), link);
      await tester.tap(find.text('Import').last);
      await tester.pumpAndSettle();

      await confirmImport(tester);
    });

    testWidgets('should import a list from a QR code', (tester) async {
      await pumpLibrary(
        tester,
        scannerBuilder: (context, onCode) => Column(
          children: [
            TextButton(
              onPressed: () => onCode('https://example.com/not-a-list'),
              child: const Text('scan other'),
            ),
            TextButton(
              onPressed: () =>
                  onCode('mediavore://share?name=Shared&items=7:movie,8:tv'),
              child: const Text('scan list'),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('library_import_list')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan QR Code'));
      await tester.pumpAndSettle();
      expect(find.text('Scan MediaVore List'), findsOneWidget);

      // A code that is not a MediaVore list keeps the scanner open.
      await tester.tap(find.text('scan other'));
      await tester.pumpAndSettle();
      expect(find.text('scan list'), findsOneWidget);

      await tester.tap(find.text('scan list'));
      await tester.pumpAndSettle();

      await confirmImport(tester);
    });

    testWidgets('should report an invalid link and import nothing', (
      tester,
    ) async {
      await pumpLibrary(tester);

      await tester.tap(find.byKey(const Key('library_import_list')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import via Link'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'https://example.com');
      await tester.tap(find.text('Import').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Invalid link format'), findsOneWidget);
      expect(find.text('Confirm Import'), findsNothing);
      verifyNever(() => repository.createList(any()));
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });
  });

  group('parseSharedListLink', () {
    test('should read the name and the entries of a share link', () {
      final shared = parseSharedListLink(
        'mediavore://share?name=My%20list&items=1:movie,2:tv',
      );

      expect(shared!.name, 'My list');
      expect(shared.entries, ['1:movie', '2:tv']);
    });

    test('should return null when the link carries no list', () {
      expect(parseSharedListLink('https://mediavore.app/share'), isNull);
      expect(parseSharedListLink('not a link'), isNull);
    });
  });
}
