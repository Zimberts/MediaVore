import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/home/presentation/widgets/upcoming_row.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

import '../../../../helpers/pump_app.dart';

final _now = DateTime(2026, 11, 14, 21);

Widget _row(NotifiedItem item) => testApp(
  UpcomingRow(
    item: item,
    now: _now,
    onOpen: () {},
    onMarkSeen: () {},
    onMenu: () {},
  ),
);

void main() {
  group('UpcomingRow', () {
    testWidgets('should show the poster instead of the date badge when the '
        'release has one', (tester) async {
      await tester.pumpWidget(
        _row(
          NotifiedItem(
            tmdbId: 1,
            type: MediaType.movie,
            title: 'Dune',
            posterPath: '/dune.jpg',
            releaseDate: DateTime(2026, 12, 18),
          ),
        ),
      );

      expect(find.byKey(const Key('upcoming_row_poster')), findsOneWidget);
      final poster = tester.widget<MediaPosterCard>(
        find.byType(MediaPosterCard),
      );
      expect(poster.data.imageUrl, endsWith('/w92/dune.jpg'));
      // The date badge is gone: its day number is not drawn on its own.
      expect(find.text('18'), findsNothing);
      // The date stays readable in the subtitle.
      expect(find.textContaining('Dec'), findsOneWidget);
    });

    testWidgets('should keep the date badge when the release has no poster', (
      tester,
    ) async {
      await tester.pumpWidget(
        _row(
          NotifiedItem(
            tmdbId: 2,
            type: MediaType.movie,
            title: 'Alien',
            releaseDate: DateTime(2026, 12, 18),
          ),
        ),
      );

      expect(find.byKey(const Key('upcoming_row_poster')), findsNothing);
      expect(find.byType(MediaPosterCard), findsNothing);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('should keep the clock badge without poster nor date', (
      tester,
    ) async {
      await tester.pumpWidget(
        _row(NotifiedItem(tmdbId: 3, type: MediaType.tv, title: 'Andor')),
      );

      expect(find.byType(MediaPosterCard), findsNothing);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });
}
