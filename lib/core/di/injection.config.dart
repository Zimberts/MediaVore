// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i5;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:isar/isar.dart' as _i6;
import 'package:shared_preferences/shared_preferences.dart' as _i12;

import '../../features/achievements/data/repositories/achievement_repository_impl.dart'
    as _i14;
import '../../features/achievements/domain/repositories/achievement_repository.dart'
    as _i13;
import '../../features/achievements/presentation/providers/achievement_provider.dart'
    as _i15;
import '../../features/media_details/data/datasources/media_list_local_data_source.dart'
    as _i8;
import '../../features/search/data/datasources/media_remote_data_source.dart'
    as _i9;
import '../../features/search/data/repositories/media_repository_impl.dart'
    as _i11;
import '../../features/search/domain/repositories/media_repository.dart'
    as _i10;
import '../cache/media_cache.dart' as _i7;
import '../database/app_database.dart' as _i17;
import 'asset_definitions_loader.dart' as _i4;
import 'definitions_loader.dart' as _i3;
import 'injection.dart' as _i16;

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
  gh.lazySingleton<_i3.DefinitionsLoader>(() => _i4.AssetDefinitionsLoader());
  gh.singleton<_i5.Dio>(() => registerModule.dio);
  await gh.singletonAsync<_i6.Isar>(
    () => databaseModule.isar,
    preResolve: true,
  );
  gh.lazySingleton<_i7.MediaCache>(() => _i7.MediaCache(gh<_i6.Isar>()));
  gh.lazySingleton<_i8.MediaListLocalDataSource>(
      () => _i8.MediaListLocalDataSource(gh<_i6.Isar>()));
  gh.lazySingleton<_i9.MediaRemoteDataSource>(() => _i9.MediaRemoteDataSource(
        dio: gh<_i5.Dio>(),
        apiToken: gh<String>(),
      ));
  gh.lazySingleton<_i10.MediaRepository>(() => _i11.MediaRepositoryImpl(
        remoteDataSource: gh<_i9.MediaRemoteDataSource>(),
        localDataSource: gh<_i8.MediaListLocalDataSource>(),
        cache: gh<_i7.MediaCache>(),
      ));
  await gh.factoryAsync<_i12.SharedPreferences>(
    () => registerModule.sharedPreferences,
    preResolve: true,
  );
  gh.singleton<String>(() => registerModule.apiToken);
  gh.lazySingleton<_i13.AchievementRepository>(
      () => _i14.AchievementRepositoryImpl(
            gh<_i6.Isar>(),
            gh<_i8.MediaListLocalDataSource>(),
            definitionsLoader: gh<_i3.DefinitionsLoader>(),
          ));
  gh.lazySingleton<_i15.AchievementProvider>(
      () => _i15.AchievementProvider(gh<_i13.AchievementRepository>()));
  return getIt;
}

class _$RegisterModule extends _i16.RegisterModule {}

class _$DatabaseModule extends _i17.DatabaseModule {}
