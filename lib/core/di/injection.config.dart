// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i3;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:isar/isar.dart' as _i4;
import 'package:shared_preferences/shared_preferences.dart' as _i10;

import '../../features/media_details/data/datasources/media_list_local_data_source.dart'
    as _i6;
import '../../features/search/data/datasources/media_remote_data_source.dart'
    as _i7;
import '../../features/search/data/repositories/media_repository_impl.dart'
    as _i9;
import '../../features/search/domain/repositories/media_repository.dart' as _i8;
import '../cache/media_cache.dart' as _i5;
import '../database/app_database.dart' as _i12;
import 'injection.dart' as _i11;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i1.GetIt> init(
  _i1.GetIt getIt, {
  String? environment,
  _i2.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i2.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  final databaseModule = _$DatabaseModule();
  gh.singleton<_i3.Dio>(() => registerModule.dio);
  await gh.singletonAsync<_i4.Isar>(
    () => databaseModule.isar,
    preResolve: true,
  );
  gh.lazySingleton<_i5.MediaCache>(() => _i5.MediaCache(gh<_i4.Isar>()));
  gh.lazySingleton<_i6.MediaListLocalDataSource>(
      () => _i6.MediaListLocalDataSource(gh<_i4.Isar>()));
  gh.lazySingleton<_i7.MediaRemoteDataSource>(() => _i7.MediaRemoteDataSource(
        dio: gh<_i3.Dio>(),
        apiToken: gh<String>(),
      ));
  gh.lazySingleton<_i8.MediaRepository>(() => _i9.MediaRepositoryImpl(
        remoteDataSource: gh<_i7.MediaRemoteDataSource>(),
        localDataSource: gh<_i6.MediaListLocalDataSource>(),
        cache: gh<_i5.MediaCache>(),
      ));
  await gh.factoryAsync<_i10.SharedPreferences>(
    () => registerModule.sharedPreferences,
    preResolve: true,
  );
  gh.singleton<String>(() => registerModule.apiToken);
  return getIt;
}

class _$RegisterModule extends _i11.RegisterModule {}

class _$DatabaseModule extends _i12.DatabaseModule {}
