import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
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
  Dio get dio => Dio();

  @singleton
  String get apiToken => dotenv.env['TMDB_API_TOKEN'] ?? '';

  @singleton
  bool get autoInit => true;

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
