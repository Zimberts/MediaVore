import 'package:isar_community/isar.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';

part 'manual_media_model.g.dart';

/// Isar collection for manually created media items absent from TMDB.
///
/// Each entry has a negative [localId] (`< 0`) so it never collides with
/// positive TMDB IDs in shared tables (`SeenItemModel`, `MediaListItem`,
/// `LikedItem`).
@collection
class ManualMediaModel {
  Id? isarId;

  @Index(unique: true)
  final int localId;

  @enumerated
  final ManualMediaKind kind;

  final String title;

  final String? originalTitle;

  final String? overview;

  final String? releaseDate;

  final int? runtime;

  /// Number of episodes per season (1-indexed: element 0 is Season 1).
  final List<int>? seasons;

  final String? posterPath;

  final List<String>? genres;

  final List<String>? originCountries;

  final String? sourceUrl;

  final String? sourceProvider;

  final DateTime createdAt;

  final DateTime updatedAt;

  ManualMediaModel({
    this.isarId,
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

  ManualMedia toEntity() => ManualMedia(
    localId: localId,
    kind: kind,
    title: title,
    originalTitle: originalTitle,
    overview: overview,
    releaseDate: releaseDate,
    runtime: runtime,
    seasons: seasons,
    posterPath: posterPath,
    genres: genres,
    originCountries: originCountries,
    sourceUrl: sourceUrl,
    sourceProvider: sourceProvider,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory ManualMediaModel.fromEntity(ManualMedia entity) => ManualMediaModel(
    localId: entity.localId,
    kind: entity.kind,
    title: entity.title,
    originalTitle: entity.originalTitle,
    overview: entity.overview,
    releaseDate: entity.releaseDate,
    runtime: entity.runtime,
    seasons: entity.seasons,
    posterPath: entity.posterPath,
    genres: entity.genres,
    originCountries: entity.originCountries,
    sourceUrl: entity.sourceUrl,
    sourceProvider: entity.sourceProvider,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
