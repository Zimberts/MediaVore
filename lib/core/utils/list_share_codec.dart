import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mediavore/core/domain/entities/media_item.dart';

/// Represents a media entry in a shared list.
class SharedMediaEntry {
  final int id;
  final MediaType type;

  const SharedMediaEntry(this.id, this.type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedMediaEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() => '$id:${type.name}';
}

/// Decoded content of a shared list link or QR code.
class ListSharePayload {
  final String name;
  final List<SharedMediaEntry> entries;
  final int version;
  final int part;
  final int totalParts;

  const ListSharePayload({
    required this.name,
    required this.entries,
    this.version = 2,
    this.part = 1,
    this.totalParts = 1,
  });
}

/// Codec for encoding and decoding shared list URLs and QR payloads.
///
/// Supports:
/// - Version 1: plain query parameters (`items=id:type,id:type`).
/// - Version 2: compact binary with delta + varint encoding, deflate compression,
///   and base64url (`v=2&name=...&d=<base64url>`).
class ListShareCodec {
  static const int currentVersion = 2;

  /// Encodes [entries] into a compact v2 base64url string.
  static String encodeV2(List<SharedMediaEntry> entries) {
    final movieIds =
        entries
            .where((e) => e.type == MediaType.movie)
            .map((e) => e.id)
            .toSet()
            .toList()
          ..sort();

    final tvIds =
        entries
            .where((e) => e.type == MediaType.tv)
            .map((e) => e.id)
            .toSet()
            .toList()
          ..sort();

    final bytes = <int>[];
    _writeVarint(bytes, movieIds.length);
    var prevMovie = 0;
    for (final id in movieIds) {
      final delta = id - prevMovie;
      _writeVarint(bytes, delta);
      prevMovie = id;
    }

    _writeVarint(bytes, tvIds.length);
    var prevTv = 0;
    for (final id in tvIds) {
      final delta = id - prevTv;
      _writeVarint(bytes, delta);
      prevTv = id;
    }

    final compressed = zlib.encode(bytes);
    return base64UrlEncode(compressed).replaceAll('=', '');
  }

  /// Decodes a v2 base64url string into a list of [SharedMediaEntry].
  static List<SharedMediaEntry> decodeV2(String encoded) {
    if (encoded.trim().isEmpty) return const [];
    try {
      final normalized = base64.normalize(encoded.trim());
      final compressed = base64Url.decode(normalized);
      final raw = Uint8List.fromList(zlib.decode(compressed));
      final offset = [0];

      final movieCount = _readVarint(raw, offset);
      final entries = <SharedMediaEntry>[];
      var prevMovie = 0;
      for (var i = 0; i < movieCount; i++) {
        final delta = _readVarint(raw, offset);
        final id = prevMovie + delta;
        entries.add(SharedMediaEntry(id, MediaType.movie));
        prevMovie = id;
      }

      final tvCount = _readVarint(raw, offset);
      var prevTv = 0;
      for (var i = 0; i < tvCount; i++) {
        final delta = _readVarint(raw, offset);
        final id = prevTv + delta;
        entries.add(SharedMediaEntry(id, MediaType.tv));
        prevTv = id;
      }

      return entries;
    } catch (_) {
      return const [];
    }
  }

  /// Decodes entries from a string in v1 format: `"123:movie,456:tv"`.
  static List<SharedMediaEntry> decodeV1(String itemsStr) {
    if (itemsStr.trim().isEmpty) return const [];
    final tokens = itemsStr.split(',');
    final entries = <SharedMediaEntry>[];
    for (final token in tokens) {
      final parts = token.trim().split(':');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      if (id == null) continue;
      final type = parts[1].toLowerCase() == 'tv'
          ? MediaType.tv
          : MediaType.movie;
      entries.add(SharedMediaEntry(id, type));
    }
    return entries;
  }

  /// Converts a list of raw entry strings (`"id:type"`) to [SharedMediaEntry].
  static List<SharedMediaEntry> parseEntries(List<String> rawEntries) {
    final entries = <SharedMediaEntry>[];
    for (final raw in rawEntries) {
      final parts = raw.split(':');
      if (parts.length != 2) continue;
      final id = int.tryParse(parts[0]);
      if (id == null) continue;
      final type = parts[1].toLowerCase() == 'tv'
          ? MediaType.tv
          : MediaType.movie;
      entries.add(SharedMediaEntry(id, type));
    }
    return entries;
  }

  /// Decodes a share [Uri], resolving either v2 (`d=...`) or v1 (`items=...`).
  static ListSharePayload? decodeUri(Uri uri) {
    final name = uri.queryParameters['name'] ?? '';
    final versionStr = uri.queryParameters['v'];
    final v = int.tryParse(versionStr ?? '1') ?? 1;

    final partStr = uri.queryParameters['part'];
    var part = 1;
    var totalParts = 1;
    if (partStr != null && partStr.contains('/')) {
      final segments = partStr.split('/');
      part = int.tryParse(segments[0]) ?? 1;
      totalParts = int.tryParse(segments[1]) ?? 1;
    }

    final d = uri.queryParameters['d'] ?? uri.queryParameters['data'];
    if (d != null && d.isNotEmpty) {
      final entries = decodeV2(d);
      return ListSharePayload(
        name: name,
        entries: entries,
        version: 2,
        part: part,
        totalParts: totalParts,
      );
    }

    final itemsStr = uri.queryParameters['items'];
    if (itemsStr != null && itemsStr.isNotEmpty) {
      final entries = decodeV1(itemsStr);
      return ListSharePayload(
        name: name,
        entries: entries,
        version: v,
        part: part,
        totalParts: totalParts,
      );
    }

    return null;
  }

  /// Parses a share link or QR payload string into a [ListSharePayload].
  static ListSharePayload? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    return decodeUri(uri);
  }

  /// Generates one or more `mediavore://together` URLs for sharing in a Together session.
  /// If [entries] exceeds [chunkSize], multiple chunked URLs with `&part=i/n` are produced.
  static List<String> createTogetherUrls({
    required String name,
    required List<SharedMediaEntry> entries,
    int chunkSize = 150,
  }) {
    if (entries.isEmpty) {
      final base = 'mediavore://together?v=2&name=${Uri.encodeComponent(name)}';
      return [base];
    }

    final chunks = <List<SharedMediaEntry>>[];
    for (var i = 0; i < entries.length; i += chunkSize) {
      chunks.add(entries.sublist(i, math.min(i + chunkSize, entries.length)));
    }

    final total = chunks.length;
    final urls = <String>[];
    for (var i = 0; i < total; i++) {
      final data = encodeV2(chunks[i]);
      final partParam = total > 1 ? '&part=${i + 1}/$total' : '';
      urls.add(
        'mediavore://together?v=2&name=${Uri.encodeComponent(name)}$partParam&d=$data',
      );
    }
    return urls;
  }

  /// Generates a share URL.
  static String createShareUrl({
    required String listName,
    required List<SharedMediaEntry> entries,
    bool customScheme = false,
    int version = currentVersion,
  }) {
    final base = customScheme
        ? 'mediavore://share'
        : 'https://mediavore.app/share';
    final encodedName = Uri.encodeComponent(listName);

    if (version == 2) {
      final encodedData = encodeV2(entries);
      return '$base?v=2&name=$encodedName&d=$encodedData';
    } else {
      final itemsStr = entries.map((e) => '${e.id}:${e.type.name}').join(',');
      return '$base?name=$encodedName&items=${Uri.encodeComponent(itemsStr)}';
    }
  }

  static void _writeVarint(List<int> bytes, int value) {
    var v = value;
    while (v >= 0x80) {
      bytes.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    bytes.add(v & 0x7F);
  }

  static int _readVarint(Uint8List bytes, List<int> offsetRef) {
    var result = 0;
    var shift = 0;
    while (true) {
      if (offsetRef[0] >= bytes.length) {
        throw const FormatException('Unexpected end of varint data');
      }
      final byte = bytes[offsetRef[0]++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }
}
