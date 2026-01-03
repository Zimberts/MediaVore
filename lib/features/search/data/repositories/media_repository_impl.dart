import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/media_details/data/datasources/watchlist_local_data_source.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Implementation of the [MediaRepository] that uses a remote and a local data source.
@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;
  final WatchlistLocalDataSource localDataSource;

  /// Creates a new instance of [MediaRepositoryImpl].
  ///
  /// Requires a [remoteDataSource] to fetch data from the network,
  /// and a [localDataSource] to manage the watchlist.
  MediaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    return remoteDataSource.searchMedia(query, page: page);
  }

  @override
  Future<MediaDetails> getMediaDetails(int id, {MediaType type = MediaType.movie}) async {
    // Fetch both the details and the credits in parallel.
    final itemFuture = remoteDataSource.getMediaItem(id, type: type);
    final creditsFuture = remoteDataSource.getMediaCredits(id, type: type);

    final item = await itemFuture;
    final credits = await creditsFuture;

    final List castResults = credits['cast'] ?? [];
    final List crewResults = credits['crew'] ?? [];

    final List<CastMember> cast =
        castResults.map((c) => CastMember.fromJson(c)).toList();
    
    final CrewMember director = crewResults
        .map((c) => CrewMember.fromJson(c))
        .firstWhere(
          (member) => member.job == 'Director' || member.job == 'Executive Producer', 
          orElse: () => CrewMember(name: 'N/A', job: 'Director'),
        );

    return MediaDetails(
      item: item,
      cast: cast,
      director: director,
    );
  }

  @override
  Future<void> addToWatchlist(int id, MediaType type) {
    return localDataSource.addToWatchlist(id, type.name);
  }

  @override
  Future<void> removeFromWatchlist(int id, MediaType type) {
    return localDataSource.removeFromWatchlist(id, type.name);
  }

  @override
  Future<List<String>> getWatchlistEntries() {
    return localDataSource.getWatchlistEntries();
  }

  @override
  Future<bool> isInWatchlist(int id, MediaType type) async {
    final entries = await localDataSource.getWatchlistEntries();
    return entries.contains('$id:${type.name}');
  }
}
