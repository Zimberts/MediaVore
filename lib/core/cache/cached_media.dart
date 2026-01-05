import 'package:isar/isar.dart';

part 'cached_media.g.dart';

@collection
class CachedMedia {
  Id? isarId;

  @Index(unique: true, composite: [CompositeIndex('type')])
  final int tmdbId;

  final String type;

  final String? mediaDetailsJson; // Store MediaDetails as JSON

  final String? mediaItemJson; // Store MediaItem as JSON

  final DateTime updatedAt;

  CachedMedia({
    required this.tmdbId,
    required this.type,
    this.mediaDetailsJson,
    this.mediaItemJson,
    required this.updatedAt,
  });
}

@collection
class CachedActorProfile {
  Id? isarId;

  @Index(unique: true)
  final int actorId;

  final String? profilePath;

  final DateTime updatedAt;

  CachedActorProfile({
    required this.actorId,
    this.profilePath,
    required this.updatedAt,
  });
}

@collection
class CachedSeason {
  Id? isarId;

  @Index(unique: true, composite: [CompositeIndex('seasonNumber')])
  final int tvId;

  final int seasonNumber;

  final String json;

  final DateTime updatedAt;

  CachedSeason({
    required this.tvId,
    required this.seasonNumber,
    required this.json,
    required this.updatedAt,
  });
}
