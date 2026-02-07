import 'package:equatable/equatable.dart';

enum MediaType { movie, tv, person, unknown }

class TVSeason extends Equatable {
  final int id;
  final int seasonNumber;
  final int episodeCount;
  final String? name;

  const TVSeason({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
    this.name,
  });

  factory TVSeason.fromJson(Map<String, dynamic> json) {
    return TVSeason(
      id: json['id'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      episodeCount: json['episode_count'] ?? 0,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'season_number': seasonNumber,
      'episode_count': episodeCount,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, seasonNumber, episodeCount, name];
}

class MediaItem extends Equatable {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final String releaseDate;
  final MediaType mediaType;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? status;
  final List<String>? genres;
  final double? voteAverage;
  final int? runtime;
  final List<TVSeason>? seasons;
  final String? nextEpisodeAirDate;
  final int? nextEpisodeNumber;
  final int? nextSeasonNumber;
  final String? lastEpisodeAirDate;
  final int? lastEpisodeNumber;
  final int? lastSeasonNumber;

  const MediaItem({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.releaseDate,
    this.mediaType = MediaType.movie,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.status,
    this.genres,
    this.voteAverage,
    this.runtime,
    this.seasons,
    this.nextEpisodeAirDate,
    this.nextEpisodeNumber,
    this.nextSeasonNumber,
    this.lastEpisodeAirDate,
    this.lastEpisodeNumber,
    this.lastSeasonNumber,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final mediaTypeStr = json['media_type'] as String?;
    final mediaType = _parseMediaType(mediaTypeStr);

    List<String>? genresList;
    if (json['genres'] != null && json['genres'] is List) {
      genresList = [];
      for (final g in (json['genres'] as List)) {
        if (g is String) {
          genresList.add(g);
        } else if (g is Map) {
          final name = g['name'];
          if (name is String) genresList.add(name);
        }
      }
    }

    List<TVSeason>? seasonsList;
    if (json['seasons'] != null && json['seasons'] is List) {
      seasonsList = [];
      for (final s in (json['seasons'] as List)) {
        if (s is Map) {
          seasonsList.add(TVSeason.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    String? nextAirDate;
    int? nextEpNum;
    int? nextSeasNum;
    if (json['next_episode_to_air'] != null &&
        json['next_episode_to_air'] is Map) {
      nextAirDate = json['next_episode_to_air']['air_date'] as String?;
      nextEpNum = json['next_episode_to_air']['episode_number'] as int?;
      nextSeasNum = json['next_episode_to_air']['season_number'] as int?;
    }

    String? lastAirDate;
    int? lastEpNum;
    int? lastSeasNum;
    if (json['last_episode_to_air'] != null &&
        json['last_episode_to_air'] is Map) {
      lastAirDate = json['last_episode_to_air']['air_date'] as String?;
      lastEpNum = json['last_episode_to_air']['episode_number'] as int?;
      lastSeasNum = json['last_episode_to_air']['season_number'] as int?;
    }

    return MediaItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      mediaType: mediaType,
      numberOfSeasons: json['number_of_seasons'] as int?,
      numberOfEpisodes: json['number_of_episodes'] as int?,
      status: json['status'] as String?,
      genres: genresList,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      runtime: json['runtime'] as int?,
      seasons: seasonsList,
      nextEpisodeAirDate: nextAirDate,
      nextEpisodeNumber: nextEpNum,
      nextSeasonNumber: nextSeasNum,
      lastEpisodeAirDate: lastAirDate,
      lastEpisodeNumber: lastEpNum,
      lastSeasonNumber: lastSeasNum,
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'movie':
        return MediaType.movie;
      case 'tv':
        return MediaType.tv;
      case 'person':
        return MediaType.person;
      default:
        return MediaType.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'release_date': releaseDate,
      'media_type': mediaType.name,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
      'status': status,
      'genres': genres,
      'vote_average': voteAverage,
      'runtime': runtime,
      'seasons': seasons?.map((s) => s.toJson()).toList(),
      'next_episode_to_air': nextEpisodeAirDate != null
          ? {
              'air_date': nextEpisodeAirDate,
              'episode_number': nextEpisodeNumber,
              'season_number': nextSeasonNumber,
            }
          : null,
      'last_episode_to_air': lastEpisodeAirDate != null
          ? {
              'air_date': lastEpisodeAirDate,
              'episode_number': lastEpisodeNumber,
              'season_number': lastSeasonNumber,
            }
          : null,
    };
  }

  MediaItem copyWith({
    int? id,
    String? title,
    String? posterPath,
    String? overview,
    String? releaseDate,
    MediaType? mediaType,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    String? status,
    List<String>? genres,
    double? voteAverage,
    int? runtime,
    List<TVSeason>? seasons,
    String? nextEpisodeAirDate,
    int? nextEpisodeNumber,
    int? nextSeasonNumber,
    String? lastEpisodeAirDate,
    int? lastEpisodeNumber,
    int? lastSeasonNumber,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      mediaType: mediaType ?? this.mediaType,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      voteAverage: voteAverage ?? this.voteAverage,
      runtime: runtime ?? this.runtime,
      seasons: seasons ?? this.seasons,
      nextEpisodeAirDate: nextEpisodeAirDate ?? this.nextEpisodeAirDate,
      nextEpisodeNumber: nextEpisodeNumber ?? this.nextEpisodeNumber,
      nextSeasonNumber: nextSeasonNumber ?? this.nextSeasonNumber,
      lastEpisodeAirDate: lastEpisodeAirDate ?? this.lastEpisodeAirDate,
      lastEpisodeNumber: lastEpisodeNumber ?? this.lastEpisodeNumber,
      lastSeasonNumber: lastSeasonNumber ?? this.lastSeasonNumber,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    posterPath,
    overview,
    releaseDate,
    mediaType,
    numberOfSeasons,
    numberOfEpisodes,
    status,
    genres,
    voteAverage,
    runtime,
    seasons,
    nextEpisodeAirDate,
    nextEpisodeNumber,
    nextSeasonNumber,
    lastEpisodeAirDate,
    lastEpisodeNumber,
    lastSeasonNumber,
  ];
}
