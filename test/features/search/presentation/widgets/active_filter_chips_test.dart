import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/search/presentation/widgets/active_filter_chips.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';

void main() {
  Widget createWidget({
    required SearchFilters filters,
    required ValueChanged<SearchFilters> onFilterChanged,
    required VoidCallback onClearAll,
  }) {
    return MaterialApp(
      theme: const DefaultLightPalette().toThemeData(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ActiveFilterChips(
          filters: filters,
          onFilterChanged: onFilterChanged,
          onClearAll: onClearAll,
        ),
      ),
    );
  }

  testWidgets('renders nothing when filters are empty', (tester) async {
    await tester.pumpWidget(
      createWidget(
        filters: const SearchFilters(),
        onFilterChanged: (_) {},
        onClearAll: () {},
      ),
    );

    expect(find.byType(InputChip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('renders chips for active filters and handles deletion', (
    tester,
  ) async {
    SearchFilters? updatedFilters;
    bool clearAllCalled = false;

    const filters = SearchFilters(
      type: MediaType.movie,
      sort: SearchSort.rating,
      period: SearchReleasePeriod.d1990s,
      genreIds: {28}, // Action
      minRating: 7.0,
      duration: MovieDuration.under105,
      hideSeen: true,
    );

    await tester.pumpWidget(
      createWidget(
        filters: filters,
        onFilterChanged: (f) => updatedFilters = f,
        onClearAll: () => clearAllCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    // Verify chips exist
    expect(find.byType(InputChip), findsNWidgets(7));
    expect(find.byType(ActionChip), findsOneWidget); // Clear all chip

    // Tap delete on the rating chip (Note 7+)
    final deleteButtons = find.byType(InputChip);
    // Delete first chip (type)
    final firstChip = tester.widget<InputChip>(deleteButtons.first);
    firstChip.onDeleted?.call();

    expect(updatedFilters, isNotNull);
    expect(updatedFilters!.type, isNull);

    // Scroll to ActionChip and tap Clear all
    await tester.ensureVisible(find.byType(ActionChip));
    await tester.tap(find.byType(ActionChip));
    expect(clearAllCalled, isTrue);
  });
}
