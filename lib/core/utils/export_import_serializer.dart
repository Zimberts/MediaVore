import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../error/exceptions.dart';

import '../../features/media_details/data/models/liked_item.dart';
import '../../features/media_details/data/models/media_list_item.dart';
import '../../features/media_details/data/models/notified_item_model.dart';
import '../../features/media_details/data/models/seen_item_model.dart';
import '../../features/media_details/data/models/quick_add_item_model.dart';

class ExportEnvelope {
  final int version;
  final DateTime exportedAt;
  final String? source;

  final List<SeenItemModel> seen;
  final List<LikedItem> likes;
  final List<NotifiedItemModel> notifications;
  final List<QuickAddItemModel> quickAdd;
  final Map<String, List<MediaListItem>> lists;

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

  /// Zip-bomb guard on uncompressed size. Real exports already exceed 100 MB,
  /// so this only catches genuinely abnormal entries.
  static const int maxEntryBytes = 1024 * 1024 * 1024;

  ExportEnvelope({
    required this.version,
    required this.exportedAt,
    this.source,
    List<SeenItemModel>? seen,
    List<LikedItem>? likes,
    List<NotifiedItemModel>? notifications,
    List<QuickAddItemModel>? quickAdd,
    Map<String, List<MediaListItem>>? lists,
    List<String>? warnings,
  }) : seen = seen ?? [],
       likes = likes ?? [],
       notifications = notifications ?? [],
       quickAdd = quickAdd ?? [],
       lists = lists ?? {},
       warnings = warnings ?? [];

  List<int> toZipBytes() {
    final archive = Archive();

    // meta.csv
    final metaCsv = csv.encode(<List<dynamic>>[
      ['version', 'exportedAt', 'source'],
      [version, _date(exportedAt), _text(source ?? '')],
    ]);
    archive.addFile(
      ArchiveFile('meta.csv', metaCsv.length, utf8.encode(metaCsv)),
    );

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
      final seenCsv = csv.encode(seenRows);
      archive.addFile(
        ArchiveFile('seen.csv', seenCsv.length, utf8.encode(seenCsv)),
      );
    }

    // likes.csv
    if (likes.isNotEmpty) {
      final likesRows = <List<dynamic>>[
        ['tmdbId', 'type', 'title'],
      ];
      for (final l in likes) {
        likesRows.add([l.tmdbId, l.type, _text(l.title)]);
      }
      final likesCsv = csv.encode(likesRows);
      archive.addFile(
        ArchiveFile('likes.csv', likesCsv.length, utf8.encode(likesCsv)),
      );
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
      final notifCsv = csv.encode(notifRows);
      archive.addFile(
        ArchiveFile(
          'notifications.csv',
          notifCsv.length,
          utf8.encode(notifCsv),
        ),
      );
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
      final listsCsv = csv.encode(listsRows);
      archive.addFile(
        ArchiveFile('lists.csv', listsCsv.length, utf8.encode(listsCsv)),
      );
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
      final qaCsv = csv.encode(qaRows);
      archive.addFile(
        ArchiveFile('quickadd.csv', qaCsv.length, utf8.encode(qaCsv)),
      );
    }

    return ZipEncoder().encode(archive);
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

    return ExportEnvelope(
      version: version,
      exportedAt: exportedAt,
      source: source,
      seen: seen,
      likes: likes,
      notifications: notifications,
      quickAdd: quickAdd,
      lists: lists,
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

  DateTime? optDate(String column) {
    final v = optText(column);
    return v == null ? null : DateTime.tryParse(v);
  }

  /// Returns the row's TMDB id, or null (with a warning) when it is missing or
  /// not a positive integer.
  int? tmdbId() {
    final id = optInt('tmdbId');
    if (id == null || id <= 0) {
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
