import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';

/// Returns a [FileImage] when [posterPath] is a local file path, or `null`
/// for TMDB relative paths, HTTP(S) URLs, or empty values.
ImageProvider? localPosterImageProvider(String? posterPath) {
  if (!TmdbImageUtils.isLocalPath(posterPath)) return null;
  final trimmed = posterPath!.trim();
  final filePath = trimmed.startsWith('file://')
      ? Uri.parse(trimmed).toFilePath()
      : trimmed;
  return FileImage(File(filePath));
}
