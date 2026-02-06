import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/data/datasources/media_remote_data_source.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/cache/media_cache.dart';

class MockDio extends Mock implements Dio {}

class MockMediaRepository extends Mock implements MediaRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockMediaRemoteDataSource extends Mock implements MediaRemoteDataSource {}

class MockMediaListLocalDataSource extends Mock implements MediaListLocalDataSource {}

class MockMediaListLocalDataSource extends Mock implements MediaListLocalDataSource {}

class MockIsar extends Mock implements Isar {}

class MockMediaCache extends Mock implements MediaCache {}

class FakeSeenItem extends Fake implements SeenItem {}
class FakeMediaItem extends Fake implements MediaItem {}
