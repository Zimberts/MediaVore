import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../../features/media_details/data/models/liked_item.dart';
import '../../features/media_details/data/models/manual_media_model.dart';
import '../../features/media_details/data/models/media_list_item.dart';
import '../../features/media_details/data/models/notified_item_model.dart';
import '../../features/media_details/data/models/quick_add_item_model.dart';
import '../../features/media_details/data/models/quick_add_opt_out_model.dart';
import '../../features/media_details/data/models/seen_item_model.dart';
import '../domain/entities/manual_media.dart';
import '../error/exceptions.dart';
import 'tmdb_image_utils.dart';

class ExportEnvelope {
  final int version;
  final DateTime exportedAt;
  final String? source;

  final List<SeenItemModel> seen;
  final List<LikedItem> likes;
  final List<NotifiedItemModel> notifications;
  final List<QuickAddItemModel> quickAdd;
  final Map<String, List<MediaListItem>> lists;

  /// Series streaks the user excluded from Quick Add.
  final List<QuickAddOptOutModel> optOuts;

  /// Manually added media items (negative local IDs).
  final List<ManualMediaModel> manualMedia;

  /// Non-fatal problems found while parsing (e.g. skipped invalid rows).
  /// Always empty for envelopes built in memory.
  final List<String> warnings;

  /// Highest format version this build can read (and the one it writes).
  static const int currentVersion = 1;

  /// Upper bounds applied when decoding an archive, to fail fast on corrupted
  /// or hostile files instead of exhausting memory.
  ///
  /// Exports only hold up to 6 CSVs; the entry cap just rejects junk ZIPs.
  static const int maxArchiveEntries = 64;

  /// Zip-bomb guard on the uncompressed size of each entry.
  static const int maxEntryBytes = 64 * 1024 * 1024;

  ExportEnvelope({
    required this.version,
    required this.exportedAt,
    this.source,
    List<SeenItemModel>? seen,
    List<LikedItem>? likes,
    List<NotifiedItemModel>? notifications,
    List<QuickAddItemModel>? quickAdd,
    Map<String, List<MediaListItem>>? lists,
    List<QuickAddOptOutModel>? optOuts,
    List<ManualMediaModel>? manualMedia,
    List<String>? warnings,
  }) : seen = seen ?? [],
       likes = likes ?? [],
       notifications = notifications ?? [],
       quickAdd = quickAdd ?? [],
       lists = lists ?? {},
       optOuts = optOuts ?? [],
       manualMedia = manualMedia ?? [],
       warnings = warnings ?? [];

  /// Serializes this envelope into a ZIP archive.
  List<int> toZipBytes() {
    final archive = Archive();

    // meta.csv
    _addCsv(archive, 'meta.csv', <List<dynamic>>[
      ['version', 'exportedAt', 'source'],
      [version, _date(exportedAt), _text(source ?? '')],
    ]);

    // seen.csv
    if (seen.isNotEmpty) {
      final seenRows = <List<dynamic>>[
        [
          'tmdbId',
          'type',
          'title',
          'posterPath',
          'seenDate',
          'seasonNumber',
          'episodeNumber',
          'runtime',
          'genres',
        ],
      ];
      for (final s in seen) {
        seenRows.add([
          s.tmdbId,
          s.type,
          _text(s.title),
          _text(s.posterPath ?? ''),
          _date(s.seenDate),
          s.seasonNumber ?? '',
          s.episodeNumber ?? '',
          s.runtime ?? '',
          _text(s.genres?.join('|') ?? ''),
        ]);
      }
      _addCsv(archive, 'seen.csv', seenRows);
    }

    // likes.csv
    if (likes.isNotEmpty) {
      final likesRows = <List<dynamic>>[
        ['tmdbId', 'type', 'title'],
      ];
      for (final l in likes) {
        likesRows.add([l.tmdbId, l.type, _text(l.title)]);
      }
      _addCsv(archive, 'likes.csv', likesRows);
    }

    // notifications.csv
    if (notifications.isNotEmpty) {
      final notifRows = <List<dynamic>>[
        [
          'tmdbId',
          'type',
          'title',
          'posterPath',
          'releaseDate',
          'seasonNumber',
          'episodeNumber',
          'autoNotify',
        ],
      ];
      for (final n in notifications) {
        notifRows.add([
          n.tmdbId,
          n.type,
          _text(n.title),
          _text(n.posterPath ?? ''),
          _optDate(n.releaseDate),
          n.seasonNumber ?? '',
          n.episodeNumber ?? '',
          n.autoNotify.toString(),
        ]);
      }
      _addCsv(archive, 'notifications.csv', notifRows);
    }

    // lists.csv
    if (lists.isNotEmpty) {
      final listsRows = <List<dynamic>>[
        ['listName', 'tmdbId', 'type', 'title', 'position'],
      ];
      for (final entry in lists.entries) {
        for (final item in entry.value) {
          listsRows.add([
            _text(item.listName),
            item.id,
            item.type,
            _text(item.title),
            item.position,
          ]);
        }
      }
      _addCsv(archive, 'lists.csv', listsRows);
    }

    // quickadd.csv
    if (quickAdd.isNotEmpty) {
      final qaRows = <List<dynamic>>[
        [
          'tmdbId',
          'type',
          'seasonNumber',
          'episodeNumber',
          'insertedAt',
          'airDate',
          'title',
          'posterPath',
        ],
      ];
      for (final q in quickAdd) {
        qaRows.add([
          q.tmdbId,
          q.type,
          q.seasonNumber?.toString() ?? '',
          q.episodeNumber?.toString() ?? '',
          _date(q.insertedAt),
          _optDate(q.airDate),
          _text(q.title ?? ''),
          _text(q.posterPath ?? ''),
        ]);
      }
      _addCsv(archive, 'quickadd.csv', qaRows);
    }

    // optouts.csv
    if (optOuts.isNotEmpty) {
      final optOutRows = <List<dynamic>>[
        ['tmdbId', 'seasonNumber', 'episodeNumber', 'optedOutAt'],
      ];
      for (final o in optOuts) {
        optOutRows.add([
          o.tmdbId,
          o.seasonNumber?.toString() ?? '',
          o.episodeNumber?.toString() ?? '',
          _date(o.optedOutAt),
        ]);
      }
      _addCsv(archive, 'optouts.csv', optOutRows);
    }

    // manualmedia.csv
    if (manualMedia.isNotEmpty) {
      final manualRows = <List<dynamic>>[
        [
          'localId',
          'kind',
          'title',
          'originalTitle',
          'overview',
          'releaseDate',
          'runtime',
          'seasons',
          'posterPath',
          'genres',
          'originCountries',
          'sourceUrl',
          'sourceProvider',
          'createdAt',
          'updatedAt',
        ],
      ];
      for (final m in manualMedia) {
        final exportPoster = TmdbImageUtils.isLocalPath(m.posterPath)
            ? ''
            : (m.posterPath ?? '');
        manualRows.add([
          m.localId,
          m.kind.name,
          _text(m.title),
          _text(m.originalTitle ?? ''),
          _text(m.overview ?? ''),
          _text(m.releaseDate ?? ''),
          m.runtime?.toString() ?? '',
          m.seasons?.join('|') ?? '',
          _text(exportPoster),
          _text(m.genres?.join('|') ?? ''),
          _text(m.originCountries?.join('|') ?? ''),
          _text(m.sourceUrl ?? ''),
          _text(m.sourceProvider ?? ''),
          _date(m.createdAt),
          _date(m.updatedAt),
        ]);
      }
      _addCsv(archive, 'manualmedia.csv', manualRows);
    }

    return ZipEncoder().encode(archive);
  }

  /// Asynchronously serializes this envelope to a ZIP archive on a background isolate.
  Future<List<int>> toZipBytesAsync() {
    return compute(_encodeArchive, this);
  }

  static List<int> _encodeArchive(ExportEnvelope envelope) {
    return envelope.toZipBytes();
  }

  /// Adds [rows] as a UTF-8 CSV entry. The declared size must be the encoded
  /// byte count, not the string length: non-ASCII titles (é, ½, ⁴…) take
  /// several bytes, and strict extractors such as macOS Archive Utility reject
  /// entries whose size does not match their content.
  static void _addCsv(Archive archive, String name, List<List<dynamic>> rows) {
    final bytes = utf8.encode(csv.encode(rows));
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  /// Asynchronously parses an archive produced by [toZipBytes] on a background isolate.
  ///
  /// Throws [ParsingException] when the archive cannot be read at all
  /// (corrupted ZIP, non-UTF-8 content, oversized entries, unsupported
  /// `version`). Individual invalid rows are skipped and reported in
  /// [warnings] instead.
  static Future<ExportEnvelope> fromZipBytesAsync(List<int> bytes) {
    return compute(fromZipBytes, bytes);
  }

  /// Parses an archive produced by [toZipBytes].
  ///
  /// Throws [ParsingException] when the archive cannot be read at all
  /// (corrupted ZIP, non-UTF-8 content, oversized entries, unsupported
  /// `version`). Individual invalid rows are skipped and reported in
  /// [warnings] instead.
  static ExportEnvelope fromZipBytes(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw ParsingException('Not a valid export archive', e);
    }
    if (archive.length > maxArchiveEntries) {
      throw ParsingException(
        'Too many entries in archive (${archive.length} > $maxArchiveEntries)',
      );
    }

    final tables = <String, List<List<dynamic>>>{};
    for (final file in archive) {
      if (!file.isFile || !_knownFiles.contains(file.name)) continue;
      if (file.size > maxEntryBytes) {
        throw ParsingException(
          '${file.name} is too large (${file.size} bytes)',
        );
      }
      try {
        final raw = file.content;
        if (raw.length > maxEntryBytes) {
          throw ParsingException('${file.name} is too large');
        }
        tables[file.name] = csv.decode(utf8.decode(raw));
      } on ParsingException {
        rethrow;
      } catch (e) {
        throw ParsingException('Cannot read ${file.name}', e);
      }
    }

    // ZipDecoder tolerates garbage input and may yield an empty archive.
    if (tables.isEmpty) {
      throw const ParsingException('Archive contains no MediaVore data');
    }

    final warnings = <String>[];
    var version = 1; // Archives without meta.csv predate versioning.
    DateTime exportedAt = DateTime.now();
    String? source;

    final metaRows = _RowReader.rowsOf('meta.csv', tables, warnings);
    if (metaRows.isNotEmpty) {
      final meta = metaRows.first;
      if (meta.has('version')) {
        final v = meta.optInt('version');
        if (v == null) {
          throw ParsingException(
            'Invalid version in meta.csv: "${meta.raw('version')}"',
          );
        }
        version = v;
      }
      exportedAt = meta.optDate('exportedAt') ?? exportedAt;
      source = meta.optText('source');
    }
    if (version < 1 || version > currentVersion) {
      throw ParsingException(
        'Unsupported export version $version '
        '(this app reads versions 1 to $currentVersion)',
      );
    }

    final seen = <SeenItemModel>[];
    for (final r in _RowReader.rowsOf('seen.csv', tables, warnings)) {
      final id = r.tmdbId();
      final type = r.mediaType();
      final seenDate = r.requiredDate('seenDate');
      if (id == null || type == null || seenDate == null) continue;
      final genres = r.optText('genres');
      seen.add(
        SeenItemModel(
          tmdbId: id,
          type: type,
          title: r.optText('title') ?? 'Unknown',
          posterPath: r.optText('posterPath'),
          seenDate: seenDate,
          seasonNumber: r.optInt('seasonNumber'),
          episodeNumber: r.optInt('episodeNumber'),
          runtime: r.optInt('runtime'),
          genres: genres?.split('|'),
        ),
      );
    }

    final likes = <LikedItem>[];
    for (final r in _RowReader.rowsOf('likes.csv', tables, warnings)) {
      final id = r.tmdbId();
      final type = r.mediaType();
      if (id == null || type == null) continue;
      likes.add(
        LikedItem(
          tmdbId: id,
          type: type,
          title: r.optText('title') ?? 'Unknown',
        ),
      );
    }

    final notifications = <NotifiedItemModel>[];
    for (final r in _RowReader.rowsOf('notifications.csv', tables, warnings)) {
      final id = r.tmdbId();
      final type = r.mediaType();
      if (id == null || type == null) continue;
      notifications.add(
        NotifiedItemModel(
          tmdbId: id,
          type: type,
          title: r.optText('title') ?? 'Unknown',
          posterPath: r.optText('posterPath'),
          releaseDate: r.optDate('releaseDate'),
          seasonNumber: r.optInt('seasonNumber'),
          episodeNumber: r.optInt('episodeNumber'),
          autoNotify: r.optText('autoNotify')?.toLowerCase() == 'true',
        ),
      );
    }

    final quickAdd = <QuickAddItemModel>[];
    for (final r in _RowReader.rowsOf('quickadd.csv', tables, warnings)) {
      final id = r.tmdbId();
      final type = r.mediaType();
      if (id == null || type == null) continue;
      quickAdd.add(
        QuickAddItemModel(
          tmdbId: id,
          type: type,
          seasonNumber: r.optInt('seasonNumber'),
          episodeNumber: r.optInt('episodeNumber'),
          insertedAt: r.optDate('insertedAt') ?? DateTime.now(),
          airDate: r.optDate('airDate'),
          title: r.optText('title'),
          posterPath: r.optText('posterPath'),
        ),
      );
    }

    final lists = <String, List<MediaListItem>>{};
    for (final r in _RowReader.rowsOf('lists.csv', tables, warnings)) {
      final id = r.tmdbId();
      final type = r.mediaType();
      final listName = r.optText('listName');
      if (listName == null) r.warn('missing listName');
      if (id == null || type == null || listName == null) continue;
      lists
          .putIfAbsent(listName, () => [])
          .add(
            MediaListItem(
              id: id,
              type: type,
              title: r.optText('title') ?? 'Unknown',
              listName: listName,
              position: r.optInt('position') ?? 0,
            ),
          );
    }

    final optOuts = <QuickAddOptOutModel>[];
    for (final r in _RowReader.rowsOf('optouts.csv', tables, warnings)) {
      final id = r.tmdbId();
      // An unreadable episode must not widen the opt-out to the whole series.
      final season = r.strictInt('seasonNumber');
      final episode = r.strictInt('episodeNumber');
      if (id == null || season.invalid || episode.invalid) continue;
      optOuts.add(
        QuickAddOptOutModel(
          tmdbId: id,
          seasonNumber: season.value,
          episodeNumber: episode.value,
          optedOutAt: r.optDate('optedOutAt') ?? exportedAt,
        ),
      );
    }

    final manualMedia = <ManualMediaModel>[];
    for (final r in _RowReader.rowsOf('manualmedia.csv', tables, warnings)) {
      final localId = r.optInt('localId');
      final kindName = r.optText('kind');
      final kind = ManualMediaKind.values
          .where((k) => k.name == kindName)
          .firstOrNull;
      final title = r.optText('title');
      if (localId == null || localId >= 0) {
        r.warn('invalid localId "${r.raw('localId') ?? ''}"');
        continue;
      }
      if (kind == null) {
        r.warn('invalid kind "${kindName ?? ''}"');
        continue;
      }
      if (title == null) {
        r.warn('missing title');
        continue;
      }
      final seasonsStr = r.optText('seasons');
      final seasons = seasonsStr
          ?.split('|')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .where((n) => n > 0)
          .toList();
      final genresStr = r.optText('genres');
      final genres = genresStr?.split('|').where((g) => g.isNotEmpty).toList();
      final countriesStr = r.optText('originCountries');
      final countries = countriesStr
          ?.split('|')
          .where((c) => c.isNotEmpty)
          .toList();
      manualMedia.add(
        ManualMediaModel(
          localId: localId,
          kind: kind,
          title: title,
          originalTitle: r.optText('originalTitle'),
          overview: r.optText('overview'),
          releaseDate: r.optText('releaseDate'),
          runtime: r.optInt('runtime'),
          seasons: seasons != null && seasons.isNotEmpty ? seasons : null,
          posterPath: r.optText('posterPath'),
          genres: genres != null && genres.isNotEmpty ? genres : null,
          originCountries: countries != null && countries.isNotEmpty
              ? countries
              : null,
          sourceUrl: r.optText('sourceUrl'),
          sourceProvider: r.optText('sourceProvider'),
          createdAt: r.optDate('createdAt') ?? exportedAt,
          updatedAt: r.optDate('updatedAt') ?? exportedAt,
        ),
      );
    }

    return ExportEnvelope(
      version: version,
      exportedAt: exportedAt,
      source: source,
      seen: seen,
      likes: likes,
      notifications: notifications,
      quickAdd: quickAdd,
      lists: lists,
      optOuts: optOuts,
      manualMedia: manualMedia,
      warnings: warnings,
    );
  }

  static const _knownFiles = {
    'meta.csv',
    'seen.csv',
    'likes.csv',
    'notifications.csv',
    'quickadd.csv',
    'lists.csv',
    'optouts.csv',
    'manualmedia.csv',
  };

  /// Dates are written in UTC with an explicit `Z` so that an export read on a
  /// device in another time zone denotes the same instant.
  static String _date(DateTime d) => d.toUtc().toIso8601String();

  static String _optDate(DateTime? d) => d == null ? '' : _date(d);

  /// Neutralises spreadsheet formula injection (OWASP "CSV injection") by
  /// prefixing a `'` to free-text cells that a spreadsheet would evaluate.
  /// Reversed on import by [unescapeText].
  static String _text(String s) => needsEscape(s) ? "'$s" : s;

  static const _formulaTriggers = {'=', '+', '-', '@', '\t', '\r'};

  /// True when [s] must be prefixed with `'` on export. A value that already
  /// starts with `'` followed by an escapable value is escaped again, which
  /// keeps the escape/unescape pair a bijection.
  @visibleForTesting
  static bool needsEscape(String s) {
    var i = 0;
    while (i < s.length && s[i] == "'") {
      i++;
    }
    return i < s.length && _formulaTriggers.contains(s[i]);
  }

  @visibleForTesting
  static String unescapeText(String s) =>
      s.startsWith("'") && needsEscape(s.substring(1)) ? s.substring(1) : s;
}

/// Reads one data row of a CSV table by column name and records per-row
/// problems as warnings (`file row N: ...`, N being the 1-based line number).
class _RowReader {
  final String _file;
  final int _line;
  final Map<String, int> _columns;
  final List<dynamic> _row;
  final List<String> _warnings;

  _RowReader(this._file, this._line, this._columns, this._row, this._warnings);

  static List<_RowReader> rowsOf(
    String file,
    Map<String, List<List<dynamic>>> tables,
    List<String> warnings,
  ) {
    final rows = tables[file];
    if (rows == null || rows.isEmpty) return const [];
    final columns = <String, int>{};
    for (var j = 0; j < rows.first.length; j++) {
      columns.putIfAbsent(rows.first[j].toString().trim(), () => j);
    }
    return [
      for (var i = 1; i < rows.length; i++)
        if (!_isBlank(rows[i]))
          _RowReader(file, i + 1, columns, rows[i], warnings),
    ];
  }

  static bool _isBlank(List<dynamic> row) =>
      row.every((c) => c == null || c.toString().trim().isEmpty);

  void warn(String message) => _warnings.add('$_file row $_line: $message');

  bool has(String column) => _columns.containsKey(column);

  dynamic raw(String column) {
    final j = _columns[column];
    return j == null || j >= _row.length ? null : _row[j];
  }

  String? optText(String column) {
    final v = raw(column)?.toString().trim();
    if (v == null || v.isEmpty) return null;
    return ExportEnvelope.unescapeText(v);
  }

  int? optInt(String column) {
    final v = raw(column);
    if (v is int) return v;
    if (v is double && v == v.truncateToDouble()) return v.toInt();
    return v == null ? null : int.tryParse(v.toString().trim());
  }

  /// [optInt] that tells an empty cell (`value` null) from an unreadable one
  /// (`invalid`, with a warning).
  ({int? value, bool invalid}) strictInt(String column) {
    final value = optInt(column);
    final invalid = value == null && optText(column) != null;
    if (invalid) warn('invalid $column "${raw(column)}"');
    return (value: value, invalid: invalid);
  }

  DateTime? optDate(String column) {
    final v = optText(column);
    return v == null ? null : DateTime.tryParse(v);
  }

  /// Returns the row's media id (positive TMDB id or negative manual id), or
  /// null (with a warning) when it is missing or zero.
  int? tmdbId() {
    final id = optInt('tmdbId');
    if (id == null || id == 0) {
      warn('invalid tmdbId "${raw('tmdbId') ?? ''}"');
      return null;
    }
    return id;
  }

  /// Returns `movie` or `tv`, or null (with a warning) for anything else.
  String? mediaType() {
    final t = optText('type');
    if (t != 'movie' && t != 'tv') {
      warn('invalid type "${t ?? ''}"');
      return null;
    }
    return t;
  }

  DateTime? requiredDate(String column) {
    final d = optDate(column);
    if (d == null) warn('invalid $column "${raw(column) ?? ''}"');
    return d;
  }
}
