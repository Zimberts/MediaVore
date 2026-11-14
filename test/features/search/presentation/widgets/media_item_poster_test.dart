import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  MediaItem item({
    MediaType type = MediaType.movie,
    String releaseDate = '2021-09-15',
    int? runtime,
    int? seasons,
    int? episodes,
    String? posterPath,
  }) => MediaItem(
    id: 1,
    title: 'Dune',
    overview: '',
    releaseDate: releaseDate,
    mediaType: type,
    runtime: runtime,
    numberOfSeasons: seasons,
    numberOfEpisodes: episodes,
    posterPath: posterPath,
  );

  group('mediaItemCaption', () {
    test('should join the year and the runtime of a film', () {
      expect(mediaItemCaption(l10n, item(runtime: 155)), '2021 · 2h 35m');
    });

    test('should join the year and the seasons of a series', () {
      expect(
        mediaItemCaption(l10n, item(type: MediaType.tv, seasons: 3)),
        '2021 · 3 saisons',
      );
    });

    test('should keep only what is known', () {
      expect(mediaItemCaption(l10n, item()), '2021');
      expect(
        mediaItemCaption(l10n, item(releaseDate: '', runtime: 90)),
        '1h 30m',
      );
      expect(mediaItemCaption(l10n, item(releaseDate: '')), '');
    });
  });

  group('mediaItemSeenState', () {
    test('should be none without any viewing', () {
      expect(mediaItemSeenState(item(), 0), MediaSeenState.none);
    });

    test('should be seen for a film with a viewing', () {
      expect(mediaItemSeenState(item(), 2), MediaSeenState.seen);
    });

    test('should be in progress until every episode is seen', () {
      final series = item(type: MediaType.tv, episodes: 10);
      expect(mediaItemSeenState(series, 4), MediaSeenState.inProgress);
      expect(mediaItemSeenState(series, 10), MediaSeenState.seen);
      expect(
        mediaItemSeenState(item(type: MediaType.tv), 4),
        MediaSeenState.inProgress,
      );
    });
  });

  group('mediaItemPosterData', () {
    testWidgets('should map a media item to the poster model', (tester) async {
      late MediaPosterData data;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) {
              data = mediaItemPosterData(
                context,
                item(type: MediaType.tv, seasons: 1, posterPath: '/p.jpg'),
                seenCount: 1,
                imageSize: 'w92',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(data.title, 'Dune');
      expect(data.kind, MediaKind.serie);
      expect(data.imageUrl, 'https://image.tmdb.org/t/p/w92/p.jpg');
      expect(data.caption, '2021 · 1 season');
      expect(data.seen, MediaSeenState.inProgress);
    });
  });
}
