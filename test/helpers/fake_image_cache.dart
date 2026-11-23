import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image cache for app-level tests: every image is a 1×1 transparent PNG,
/// served without network and without the platform database (sqflite on
/// Android, iOS and macOS hosts).
///
/// Install it as `CachedNetworkImageProvider.defaultCacheManager`, after
/// faking `path_provider` (the files go to its temporary directory).
CacheManager fakeImageCacheManager(FakeImageService service) => CacheManager(
  Config(
    'mediavore_test_images',
    repo: NonStoringObjectProvider(),
    fileService: service,
  ),
);

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
