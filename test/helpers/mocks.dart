import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mediavore/features/search/domain/repositories/movie_repository.dart';
import 'package:mediavore/features/search/data/datasources/movie_remote_data_source.dart';
import 'package:mediavore/features/movie_details/data/datasources/watchlist_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

class MockMovieRepository extends Mock implements MovieRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockMovieRemoteDataSource extends Mock implements MovieRemoteDataSource {}

class MockWatchlistLocalDataSource extends Mock implements WatchlistLocalDataSource {}
