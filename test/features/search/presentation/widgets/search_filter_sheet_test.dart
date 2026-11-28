import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);
  Widget createWidget({
    required SearchFilters initialFilters,
    required ValueChanged<SearchFilters> onApply,
    int? resultCount,
  }) {
    return MaterialApp(
      theme: const DefaultLightPalette().toThemeData(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 1200,
          width: 800,
          child: SearchFilterSheet(
            initialFilters: initialFilters,
            onApply: onApply,
            resultCount: resultCount,
          ),
        ),
      ),
    );
  }

  testWidgets('SearchFilterSheet displays all filter sections', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createWidget(initialFilters: const SearchFilters(), onApply: (_) {}),
    );
    await tester.pumpAndSettle();

    // Verify sections and headers exist
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Release year'), findsOneWidget);
    expect(find.text('Genres'), findsOneWidget);
    expect(find.text('Minimum rating'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text("Hide what I've already seen or read"), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Show results'), findsOneWidget);
  });

  testWidgets('displays result count on apply button when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(
        initialFilters: const SearchFilters(),
        onApply: (_) {},
        resultCount: 42,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show 42 results'), findsOneWidget);
  });

  testWidgets(
    'selecting filters and tapping apply returns updated SearchFilters',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SearchFilters? applied;

      await tester.pumpWidget(
        createWidget(
          initialFilters: const SearchFilters(),
          onApply: (filters) => applied = filters,
        ),
      );
      await tester.pumpAndSettle();

      // Select Movies type
      await tester.tap(find.text('Movies'));
      await tester.pumpAndSettle();

      // Select Top rated
      await tester.tap(find.text('Top rated'));
      await tester.pumpAndSettle();

      // Select 7+
      await tester.tap(find.text('7+'));
      await tester.pumpAndSettle();

      // Toggle Hide seen
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied!.type, MediaType.movie);
      expect(applied!.sort, SearchSort.rating);
      expect(applied!.minRating, 7.0);
      expect(applied!.hideSeen, isTrue);
    },
  );

  testWidgets('Clear all button resets all selections to default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createWidget(
        initialFilters: const SearchFilters(
          type: MediaType.movie,
          sort: SearchSort.rating,
          minRating: 8.0,
          hideSeen: true,
        ),
        onApply: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    // Tap Clear all
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    // 'Both' type choice chip at the top should be selected
    final allTypeChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Both'),
    );
    expect(allTypeChip.selected, isTrue);

    // Scroll down to check Switch is reset to false
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isFalse);
  });

  testWidgets('Duration indicates not applicable when TV shows is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createWidget(
        initialFilters: const SearchFilters(type: MediaType.tv),
        onApply: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('(Not applicable to TV shows)'), findsOneWidget);
  });

  testWidgets(
    'Swiper mode shows excluded genres, language and hideUnreleased',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SearchFilters? applied;

      await tester.pumpWidget(
        MaterialApp(
          theme: const DefaultLightPalette().toThemeData(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 1200,
              width: 800,
              child: SearchFilterSheet(
                initialFilters: const SearchFilters(),
                showTypeFilter: false,
                showHideSeen: false,
                showExcludedGenres: true,
                showLanguageFilter: true,
                showHideUnreleased: true,
                moviesOnly: true,
                onApply: (f) => applied = f,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type & HideSeen are hidden
      expect(find.text('Media type'), findsNothing);
      expect(find.text("Hide what I've already seen or read"), findsNothing);

      // Excluded genres, language and hideUnreleased are visible
      expect(find.text('Exclude genres'), findsOneWidget);

      final sheetScrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Hide unreleased movies'),
        300,
        scrollable: sheetScrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Original language'), findsOneWidget);
      expect(find.text('Hide unreleased movies'), findsOneWidget);

      await tester.tap(find.text('Japanese'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show results'));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied!.originalLanguage, 'ja');
      expect(applied!.hideUnreleased, isTrue);
    },
  );
}
