import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/features/search/presentation/widgets/search_people_row.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchPeopleRow', () {
    testWidgets('renders SizedBox.shrink when list is empty', (tester) async {
      await tester.pumpWidget(testApp(const SearchPeopleRow(people: [])));

      expect(find.byType(SearchPeopleRow), findsOneWidget);
      expect(
        find.byKey(const Key('search_people_section_header')),
        findsNothing,
      );
      expect(find.byKey(const Key('search_people_list_view')), findsNothing);
    });

    testWidgets('renders people section and items when list is not empty', (
      tester,
    ) async {
      const people = [
        PersonSummary(
          id: 1,
          name: 'Denis Villeneuve',
          knownForDepartment: 'Directing',
        ),
        PersonSummary(
          id: 2,
          name: 'Timothée Chalamet',
          knownForTitles: ['Dune', 'Wonka'],
        ),
      ];

      await tester.pumpWidget(testApp(const SearchPeopleRow(people: people)));

      expect(
        find.byKey(const Key('search_people_section_header')),
        findsOneWidget,
      );
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Denis Villeneuve'), findsOneWidget);
      expect(find.text('Directing'), findsOneWidget);
      expect(find.text('Timothée Chalamet'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);
    });
  });
}
