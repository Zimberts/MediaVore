import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Kind of manually added media item.
enum ManualMediaKind {
  movie,
  tv,
  video,
  videoSeries;

  /// Underlying [MediaType] used for shared tables (seen, lists, likes).
  MediaType get mediaType =>
      (this == tv || this == videoSeries) ? MediaType.tv : MediaType.movie;

  /// Whether this kind has seasons and episodes.
  bool get isSeries => this == tv || this == videoSeries;
}

/// Pure domain entity representing a manually created media item absent from TMDB.
///
/// Identified by a negative [localId] (`< 0`), which guarantees zero collision
/// with positive TMDB IDs in shared user tables (`SeenItemModel`,
/// `MediaListItem`, `LikedItem`, etc.).
class ManualMedia extends Equatable {
  final int localId;
  final ManualMediaKind kind;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? releaseDate;
  final int? runtime;
  final List<int>? seasons;
  final String? posterPath;
  final List<String>? genres;
  final List<String>? originCountries;
  final String? sourceUrl;
  final String? sourceProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ManualMedia({
    required this.localId,
    required this.kind,
    required this.title,
    this.originalTitle,
    this.overview,
    this.releaseDate,
    this.runtime,
    this.seasons,
    this.posterPath,
    this.genres,
    this.originCountries,
    this.sourceUrl,
    this.sourceProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  MediaItem toMediaItem() {
    final seasonList = seasons;
    final tvSeasons = seasonList == null || seasonList.isEmpty
        ? null
        : [
            for (var i = 0; i < seasonList.length; i++)
              TVSeason(
                id: -(i + 1),
                seasonNumber: i + 1,
                episodeCount: seasonList[i],
              ),
          ];
    final totalEpisodes = seasonList == null || seasonList.isEmpty
        ? null
        : seasonList.fold<int>(0, (sum, count) => sum + count);

    return MediaItem(
      id: localId,
      title: title,
      originalTitle: originalTitle,
      posterPath: posterPath,
      overview: overview ?? '',
      releaseDate: releaseDate ?? '',
      mediaType: kind.mediaType,
      numberOfSeasons: tvSeasons?.length,
      numberOfEpisodes: totalEpisodes,
      genres: genres,
      originCountries: originCountries,
      runtime: runtime,
      seasons: tvSeasons,
    );
  }

  MediaDetails toMediaDetails() =>
      MediaDetails(item: toMediaItem(), cast: const []);

  ManualMedia copyWith({
    int? localId,
    ManualMediaKind? kind,
    String? title,
    String? Function()? originalTitle,
    String? Function()? overview,
    String? Function()? releaseDate,
    int? Function()? runtime,
    List<int>? Function()? seasons,
    String? Function()? posterPath,
    List<String>? Function()? genres,
    List<String>? Function()? originCountries,
    String? Function()? sourceUrl,
    String? Function()? sourceProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ManualMedia(
      localId: localId ?? this.localId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      originalTitle: originalTitle != null
          ? originalTitle()
          : this.originalTitle,
      overview: overview != null ? overview() : this.overview,
      releaseDate: releaseDate != null ? releaseDate() : this.releaseDate,
      runtime: runtime != null ? runtime() : this.runtime,
      seasons: seasons != null ? seasons() : this.seasons,
      posterPath: posterPath != null ? posterPath() : this.posterPath,
      genres: genres != null ? genres() : this.genres,
      originCountries: originCountries != null
          ? originCountries()
          : this.originCountries,
      sourceUrl: sourceUrl != null ? sourceUrl() : this.sourceUrl,
      sourceProvider: sourceProvider != null
          ? sourceProvider()
          : this.sourceProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    localId,
    kind,
    title,
    originalTitle,
    overview,
    releaseDate,
    runtime,
    seasons,
    posterPath,
    genres,
    originCountries,
    sourceUrl,
    sourceProvider,
    createdAt,
    updatedAt,
  ];
}
