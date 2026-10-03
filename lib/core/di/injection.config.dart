// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/achievements/data/repositories/achievement_repository_impl.dart'
    as _i445;
import '../../features/achievements/domain/repositories/achievement_repository.dart'
    as _i282;
import '../../features/achievements/presentation/providers/achievement_provider.dart'
    as _i393;
import '../../features/media_details/data/datasources/media_list_local_data_source.dart'
    as _i801;
import '../../features/search/data/datasources/media_remote_data_source.dart'
    as _i763;
import '../../features/search/data/repositories/media_repository_impl.dart'
    as _i922;
import '../../features/search/domain/repositories/media_repository.dart'
    as _i386;
import '../cache/cache_warmup_policy.dart' as _i356;
import '../cache/media_cache.dart' as _i384;
import '../database/app_database.dart' as _i982;
import '../l10n/locale_service.dart' as _i903;
import '../security/tmdb_credential_store.dart' as _i1033;
import 'asset_definitions_loader.dart' as _i719;
import 'definitions_loader.dart' as _i216;
import 'injection.dart' as _i464;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i174.GetIt> init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final registerModule = _$RegisterModule();
  final databaseModule = _$DatabaseModule();
  await gh.factoryAsync<_i460.SharedPreferences>(
    () => registerModule.sharedPreferences,
    preResolve: true,
  );
  await gh.singletonAsync<_i214.Isar>(
    () => databaseModule.isar,
    preResolve: true,
  );
  gh.singleton<_i361.Dio>(() => registerModule.dio);
  gh.singleton<bool>(() => registerModule.autoInit);
  gh.singleton<_i558.FlutterSecureStorage>(() => registerModule.secureStorage);
  gh.lazySingleton<_i356.CacheWarmupPolicy>(
    () => _i356.CacheWarmupPolicy(gh<_i460.SharedPreferences>()),
  );
  gh.lazySingleton<_i903.LocaleService>(
    () => _i903.LocaleService(gh<_i460.SharedPreferences>()),
  );
  gh.lazySingleton<_i384.MediaCache>(() => _i384.MediaCache(gh<_i214.Isar>()));
  gh.lazySingleton<_i801.MediaListLocalDataSource>(
    () => _i801.MediaListLocalDataSource(gh<_i214.Isar>()),
  );
  gh.lazySingleton<_i216.DefinitionsLoader>(
    () => _i719.AssetDefinitionsLoader(),
  );
  await gh.singletonAsync<_i1033.TmdbCredentialStore>(
    () => registerModule.tmdbCredentialStore(
      gh<_i558.FlutterSecureStorage>(),
      gh<_i460.SharedPreferences>(),
    ),
    preResolve: true,
  );
  gh.lazySingleton<_i763.MediaRemoteDataSource>(
    () => _i763.MediaRemoteDataSource(
      dio: gh<_i361.Dio>(),
      credentials: gh<_i1033.TmdbCredentialStore>(),
      locale: gh<_i903.LocaleService>(),
    ),
  );
  gh.lazySingleton<_i282.AchievementRepository>(
    () => _i445.AchievementRepositoryImpl(
      gh<_i214.Isar>(),
      gh<_i801.MediaListLocalDataSource>(),
      definitionsLoader: gh<_i216.DefinitionsLoader>(),
    ),
  );
  gh.lazySingleton<_i393.AchievementProvider>(
    () => _i393.AchievementProvider(gh<_i282.AchievementRepository>()),
  );
  gh.lazySingleton<_i386.MediaRepository>(
    () => _i922.MediaRepositoryImpl(
      remoteDataSource: gh<_i763.MediaRemoteDataSource>(),
      localDataSource: gh<_i801.MediaListLocalDataSource>(),
      cache: gh<_i384.MediaCache>(),
      warmupPolicy: gh<_i356.CacheWarmupPolicy>(),
      localeService: gh<_i903.LocaleService>(),
      autoInit: gh<bool>(),
    ),
  );
  return getIt;
}

class _$RegisterModule extends _i464.RegisterModule {}

class _$DatabaseModule extends _i982.DatabaseModule {}
