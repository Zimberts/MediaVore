// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/movie_details/data/datasources/watchlist_local_data_source.dart'
    as _i656;
import '../../features/search/data/datasources/movie_remote_data_source.dart'
    as _i797;
import '../../features/search/data/repositories/movie_repository_impl.dart'
    as _i219;
import '../../features/search/domain/repositories/movie_repository.dart'
    as _i85;
import 'injection.dart' as _i464;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final registerModule = _$RegisterModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => registerModule.sharedPreferences,
    preResolve: true,
  );
  gh.singleton<_i361.Dio>(() => registerModule.dio);
  gh.singleton<String>(() => registerModule.apiToken);
  gh.lazySingleton<_i656.WatchlistLocalDataSource>(
    () => _i656.WatchlistLocalDataSource(gh<_i460.SharedPreferences>()),
  );
  gh.lazySingleton<_i797.MovieRemoteDataSource>(
    () => _i797.MovieRemoteDataSource(
      dio: gh<_i361.Dio>(),
      apiToken: gh<String>(),
    ),
  );
  gh.lazySingleton<_i85.MovieRepository>(
    () => _i219.MovieRepositoryImpl(
      remoteDataSource: gh<_i797.MovieRemoteDataSource>(),
      localDataSource: gh<_i656.WatchlistLocalDataSource>(),
    ),
  );
  return getIt;
}

class _$RegisterModule extends _i464.RegisterModule {}
