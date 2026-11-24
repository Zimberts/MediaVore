import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart' show File;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image cache for app-level tests: every image is a 1×1 transparent PNG,
/// served without network, without the platform database (sqflite on
/// Android, iOS and macOS hosts) and without path_provider. Files go to
/// [directory].
///
/// Install it as `CachedNetworkImageProvider.defaultCacheManager`. Never read
/// that field before: its first read builds the real `DefaultCacheManager`.
CacheManager fakeImageCacheManager(
  FakeImageService service,
  io.Directory directory,
) => CacheManager(
  Config(
    'mediavore_test_images',
    repo: NonStoringObjectProvider(),
    fileService: service,
    fileSystem: _DirectoryFileSystem(directory.path),
  ),
);

/// Cache files in a fixed directory, created on demand.
class _DirectoryFileSystem implements FileSystem {
  _DirectoryFileSystem(this.path);

  final String path;

  @override
  Future<File> createFile(String name) async {
    final directory = const LocalFileSystem().directory(path);
    await directory.create(recursive: true);
    return directory.childFile(name);
  }
}

/// Records the image URLs the app asked for and answers a transparent PNG.
class FakeImageService extends FileService {
  /// Every image requested, in order.
  final List<Uri> requests = [];

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    requests.add(Uri.parse(url));
    return _PngResponse();
  }
}

final List<int> _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

class _PngResponse implements FileServiceResponse {
  @override
  Stream<List<int>> get content => Stream.value(_transparentPng);

  @override
  int get contentLength => _transparentPng.length;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 7));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.png';
}
