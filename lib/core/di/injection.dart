import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart';
import 'package:mediavore/features/search/data/repositories/movie_repository_impl.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
import 'package:mediavore/features/movie_details/data/datasources/watchlist_local_data_source.dart';

final GetIt locator = GetIt.instance;

@module
abstract class RegisterModule {
  @singleton
  http.Client get httpClient => http.Client();

  @preResolve
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
}

@LazySingleton(as: MovieRepository)
class MovieRepositoryImplInjectable extends MovieRepositoryImpl {
  MovieRepositoryImplInjectable(
    @Named('remote') MovieRemoteDataSource remoteDataSource,
    @Named('local') WatchlistLocalDataSource localDataSource,
  ) : super(remoteDataSource: remoteDataSource, localDataSource: localDataSource);
}

@LazySingleton(as: MovieRemoteDataSource, env: [Environment.prod])
@Named('remote')
class MovieRemoteDataSourceInjectable extends MovieRemoteDataSource {
  MovieRemoteDataSourceInjectable(http.Client client) : super(client: client);
}

@LazySingleton(as: WatchlistLocalDataSource, env: [Environment.prod])
@Named('local')
class WatchlistLocalDataSourceInjectable extends WatchlistLocalDataSource {
  WatchlistLocalDataSourceInjectable(super.prefs);
}