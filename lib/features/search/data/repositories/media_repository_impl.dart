import 'package:injectable/injectable.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Implementation of the [MediaRepository] that uses a remote and a local data source.
@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;
  final MediaListLocalDataSource localDataSource;

  /// Creates a new instance of [MediaRepositoryImpl].
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
  Future<ActorDetails> getActorDetails(int actorId) async {
    final actorDetailsFuture = remoteDataSource.getActorDetails(actorId);
    final actorMediasFuture = remoteDataSource.getActorMediaCredits(actorId);

    final actorDetails = await actorDetailsFuture;
    final items = await actorMediasFuture;

    return ActorDetails(
      id: actorDetails.id,
      name: actorDetails.name,
      biography: actorDetails.biography,
      birthday: actorDetails.birthday,
      placeOfBirth: actorDetails.placeOfBirth,
      profilePath: actorDetails.profilePath,
      items: items,
    );
  }

  @override
  Future<void> addToList(MediaItem item, String listName) {
    return localDataSource.addToList(
      id: item.id,
      type: item.mediaType.name,
      listName: listName,
      title: item.title,
      posterPath: item.posterPath,
    );
  }

  @override
  Future<void> removeFromList(int id, MediaType type, String listName) {
    return localDataSource.removeFromList(id, type.name, listName);
  }

  @override
  Future<List<String>> getListEntries(String listName) {
    return localDataSource.getListEntries(listName);
  }

  @override
  Future<bool> isInList(int id, MediaType type, String listName) async {
    final entries = await localDataSource.getListEntries(listName);
    return entries.contains('$id:${type.name}');
  }

  @override
  Future<List<String>> getAllListNames() {
    return localDataSource.getAllListNames();
  }

  @override
  Future<void> createList(String name) {
    return localDataSource.createList(name);
  }

  @override
  Future<void> deleteList(String name) {
    return localDataSource.deleteList(name);
  }

  @override
  Future<void> addToWatchlist(MediaItem item) {
    return addToList(item, 'watchlist');
  }

  @override
  Future<void> removeFromWatchlist(int id, MediaType type) {
    return removeFromList(id, type, 'watchlist');
  }

  @override
  Future<List<String>> getWatchlistEntries() {
    return getListEntries('watchlist');
  }

  @override
  Future<bool> isInWatchlist(int id, MediaType type) {
    return isInList(id, type, 'watchlist');
  }

  @override
  Future<List<MediaItemPreview>> getListPreviews(String listName, {int limit = 4}) async {
    final items = await localDataSource.getListItems(listName);
    return items.take(limit).map((item) => MediaItemPreview(
      id: item.id,
      title: item.title,
      posterPath: item.posterPath,
      type: item.type,
    )).toList();
  }
}
