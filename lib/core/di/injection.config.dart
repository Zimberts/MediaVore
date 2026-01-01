// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mediavore/core/di/injection.dart' as _i1062;
import 'package:mediavore/features/movie_details/data/datasources/watchlist_local_data_source.dart'
    as _i567;
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart'
    as _i144;
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart'
    as _i435;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i144.MovieRemoteDataSource>(
      () => _i1062.MovieRemoteDataSourceInjectable(gh<_i519.Client>()),
      instanceName: 'remote',
      registerFor: {_prod},
    );
    gh.lazySingleton<_i567.WatchlistLocalDataSource>(
      () => _i1062.WatchlistLocalDataSourceInjectable(
        gh<_i460.SharedPreferences>(),
      ),
      instanceName: 'local',
      registerFor: {_prod},
    );
    gh.lazySingleton<_i435.MovieRepository>(
      () => _i1062.MovieRepositoryImplInjectable(
        gh<_i144.MovieRemoteDataSource>(instanceName: 'remote'),
        gh<_i567.WatchlistLocalDataSource>(instanceName: 'local'),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i1062.RegisterModule {}
