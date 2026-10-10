import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/network/tmdb_dio.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: false,
)
void configureDependencies() {}

@module
abstract class RegisterModule {
  @singleton
  Dio get dio => createTmdbDio();
  @singleton
  bool get autoInit => true;

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @preResolve
  @singleton
  Future<TmdbCredentialStore> tmdbCredentialStore(
    FlutterSecureStorage secureStorage,
    SharedPreferences prefs,
  ) => TmdbCredentialStore.load(secureStorage: secureStorage, prefs: prefs);
}
