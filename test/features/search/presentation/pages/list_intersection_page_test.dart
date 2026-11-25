import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/search/presentation/pages/list_intersection_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository repo;
  late SearchProvider provider;

  setUpAll(() {
    registerFallbackValue(MediaType.movie);
    registerFallbackValue(<MediaItem>[]);
    registerFallbackValue(<(int, MediaType)>[]);
    registerFallbackValue(
      const MediaItem(id: 0, title: '', overview: '', releaseDate: ''),
    );
  });

  setUp(() async {
    repo = MockMediaRepository();
    when(
      () => repo.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist', 'Favorites']);
    when(
      () => repo.getWatchlistEntries(),
    ).thenAnswer((_) async => ['101:movie', '102:movie', '201:tv']);
    when(
      () => repo.getListEntries('watchlist'),
    ).thenAnswer((_) async => ['101:movie', '102:movie', '201:tv']);
    when(
      () => repo.getListEntries('Favorites'),
    ).thenAnswer((_) async => ['101:movie']);
    when(
      () => repo.getListPreviews(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => repo.getCacheSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenDbSize()).thenAnswer((_) async => 0);
    when(() => repo.getSeenItems()).thenAnswer(
      (_) async => [
        SeenItem(
          tmdbId: 101,
          type: MediaType.movie,
          title: 'Movie 101',
          seenDate: DateTime(2025),
        ),
      ],
    );
    when(() => repo.getLikedEntries()).thenAnswer((_) async => []);
    when(() => repo.getNotifiedItems()).thenAnswer((_) async => []);
    when(() => repo.getQuickAddItems()).thenAnswer((_) async => []);
    when(
      () => repo.watchNotifiedItems(),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => repo.getMediaDetails(any(), type: any(named: 'type')),
    ).thenAnswer(
      (inv) async => MediaDetails(
        item: MediaItem(
          id: inv.positionalArguments[0] as int,
          title: 'Movie ${inv.positionalArguments[0]}',
          overview: 'Overview',
          releaseDate: '2025-01-01',
          mediaType:
              (inv.namedArguments[#type] as MediaType?) ?? MediaType.movie,
        ),
        cast: const [],
      ),
    );

    when(() => repo.createList(any())).thenAnswer((_) async {});
    when(() => repo.addToList(any(), any())).thenAnswer((_) async {});
    when(() => repo.addAllToList(any(), any())).thenAnswer((_) async {});
    when(() => repo.getCachedMediaItems(any())).thenAnswer(
      (invocation) async => List<MediaItem?>.filled(
        (invocation.positionalArguments[0] as List<(int, MediaType)>).length,
        null,
      ),
    );

    provider = SearchProvider(repo);
    await provider.loadListNames();
    await provider.loadWatchlist();
    await provider.loadAllSeenStatus();
  });

  Widget buildTestWidget(ListSharePayload payload) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SearchProvider>.value(value: provider),
      ],
      child: MaterialApp(
        theme: AppPalette.ink.toThemeData(),
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListIntersectionPage(sharedPayload: payload),
      ),
    );
  }

  testWidgets('displays comparison header and common items', (tester) async {
    const payload = ListSharePayload(
      name: 'Bob List',
      entries: [
        SharedMediaEntry(101, MediaType.movie),
        SharedMediaEntry(102, MediaType.movie),
        SharedMediaEntry(999, MediaType.movie),
      ],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.pumpAndSettle();

    expect(find.text('Bob List'), findsOneWidget);
    expect(find.text('∩'), findsOneWidget);
    expect(find.byKey(const Key('compare_my_list_dropdown')), findsOneWidget);

    // Common items: 101 and 102 (both in watchlist)
    expect(find.text('Movie 101'), findsOneWidget);
    expect(find.text('Movie 102'), findsOneWidget);
    expect(find.text('Movie 999'), findsNothing);
  });

  testWidgets('toggling "Masquer mes vus" hides seen common items', (
    tester,
  ) async {
    const payload = ListSharePayload(
      name: 'Bob List',
      entries: [
        SharedMediaEntry(101, MediaType.movie),
        SharedMediaEntry(102, MediaType.movie),
      ],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.pumpAndSettle();

    // 101 is marked seen, 102 is unseen
    expect(find.text('Movie 101'), findsOneWidget);
    expect(find.text('Movie 102'), findsOneWidget);

    // Tap filter chip
    await tester.tap(find.byKey(const Key('hide_seen_toggle_chip')));
    await tester.pumpAndSettle();

    // 101 should be hidden, 102 remains visible
    expect(find.text('Movie 101'), findsNothing);
    expect(find.text('Movie 102'), findsOneWidget);
  });

  testWidgets('displays empty state when intersection is empty', (
    tester,
  ) async {
    const payload = ListSharePayload(
      name: 'Bob List',
      entries: [SharedMediaEntry(888, MediaType.movie)],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.pumpAndSettle();

    expect(find.text('Movie 888'), findsNothing);
    expect(
      find.byKey(const Key('save_intersection_as_list_button')),
      findsNothing,
    );
  });

  testWidgets('save intersection button opens dialog and creates list', (
    tester,
  ) async {
    const payload = ListSharePayload(
      name: 'Bob List',
      entries: [SharedMediaEntry(102, MediaType.movie)],
    );

    await tester.pumpWidget(buildTestWidget(payload));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(
      const Key('save_intersection_as_list_button'),
    );
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.byType(AlertDialog), findsOneWidget);
    final saveConfirmBtn = find.widgetWithText(FilledButton, 'Enregistrer');
    expect(saveConfirmBtn, findsOneWidget);

    await tester.tap(saveConfirmBtn);
    await tester.pumpAndSettle();

    verify(() => repo.createList(any())).called(1);
  });
}
