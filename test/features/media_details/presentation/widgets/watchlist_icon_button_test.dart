import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/library/presentation/providers/library_provider.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockMediaRepository mockRepository;
  late LibraryProvider libraryProvider;

  const tMovie = MediaItem(
    id: 101,
    title: 'Inception',
    overview: 'Dream within a dream',
    releaseDate: '2010-07-16',
    mediaType: MediaType.movie,
  );

  setUpAll(() {
    registerFallbackValue(tMovie);
    registerFallbackValue(MediaType.movie);
  });

  setUp(() {
    mockRepository = MockMediaRepository();
    when(
      () => mockRepository.getAllListNames(),
    ).thenAnswer((_) async => ['watchlist']);
    when(
      () => mockRepository.getListEntries(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getListPreviews(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.getWatchlistEntries(),
    ).thenAnswer((_) async => []);
    when(() => mockRepository.getLikedEntries()).thenAnswer((_) async => []);
    when(() => mockRepository.addToList(any(), any())).thenAnswer((_) async {});
    when(
      () => mockRepository.removeFromList(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.toggleNotification(
        any(),
        autoNotify: any(named: 'autoNotify'),
      ),
    ).thenAnswer((_) async {});

    libraryProvider = LibraryProvider(mockRepository);
  });

  tearDown(() {
    libraryProvider.dispose();
  });

  Widget buildWidget({bool onImage = false}) {
    return ChangeNotifierProvider<LibraryProvider>.value(
      value: libraryProvider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: DefaultLightPalette().toThemeData(),
        builder: (context, child) => AppMessageHost(child: child!),
        home: Scaffold(
          body: WatchlistIconButton(item: tMovie, onImage: onImage),
        ),
      ),
    );
  }

  group('WatchlistIconButton', () {
    testWidgets(
      'shows bookmark border when not in watchlist and updates immediately on tap',
      (tester) async {
        await libraryProvider.init();
        final completer = Completer<void>();
        when(
          () => mockRepository.addToList(any(), any()),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsNothing);

        await tester.tap(find.byType(WatchlistIconButton));
        await tester.pump();

        // Should flip to bookmark icon immediately before addToList completes
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border), findsNothing);

        completer.complete();
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      },
    );

    testWidgets(
      'reverts to border and shows error toast when addToList throws',
      (tester) async {
        await libraryProvider.init();
        when(
          () => mockRepository.addToList(any(), any()),
        ).thenThrow(Exception('Isar write error'));

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

        await tester.tap(find.byType(WatchlistIconButton));
        await tester.pumpAndSettle();

        // Reverts back to border
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsNothing);
        expect(find.byType(AppMessageHost), findsOneWidget);
      },
    );
  });
}
