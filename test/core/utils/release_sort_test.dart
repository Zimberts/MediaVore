import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/release_sort.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

void main() {
  test('sortReleases orders concrete dates first and unplanned groups last', () {
    final datedEarly = NotifiedItem(
      tmdbId: 1,
      type: MediaType.movie,
      title: 'Early Movie',
      releaseDate: DateTime(2026, 5, 1),
    );
    final datedLate = NotifiedItem(
      tmdbId: 2,
      type: MediaType.tv,
      title: 'Later Episode',
      releaseDate: DateTime(2026, 6, 1),
      seasonNumber: 2,
      episodeNumber: 4,
    );
    final episodeTba = NotifiedItem(
      tmdbId: 3,
      type: MediaType.tv,
      title: 'Episode TBA',
      seasonNumber: 1,
      episodeNumber: 8,
    );
    final returning = NotifiedItem(
      tmdbId: 4,
      type: MediaType.tv,
      title: 'Returning Show',
    );
    final plannedMovie = NotifiedItem(
      tmdbId: 5,
      type: MediaType.movie,
      title: 'Planned Film',
    );

    final sorted = sortReleases([
      plannedMovie,
      returning,
      episodeTba,
      datedLate,
      datedEarly,
    ]);

    expect(
      sorted.map((item) => item.tmdbId).toList(),
      [1, 2, 3, 4, 5],
    );
  });

  test('releaseSubtitleForItem labels unplanned groups', () {
    expect(
      releaseSubtitleForItem(
        NotifiedItem(
          tmdbId: 1,
          type: MediaType.tv,
          title: 'Episode TBA',
          seasonNumber: 2,
          episodeNumber: 1,
        ),
      ),
      'Episode — date TBA',
    );

    expect(
      releaseSubtitleForItem(
        NotifiedItem(
          tmdbId: 2,
          type: MediaType.tv,
          title: 'Returning Show',
        ),
      ),
      'Returning — new season planned',
    );

    expect(
      releaseSubtitleForItem(
        NotifiedItem(
          tmdbId: 3,
          type: MediaType.movie,
          title: 'Planned Film',
        ),
      ),
      'Planned — no release date',
    );
  });
}
