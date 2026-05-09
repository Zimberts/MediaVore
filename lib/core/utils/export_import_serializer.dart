import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';

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

  ExportEnvelope({
    required this.version,
    required this.exportedAt,
    this.source,
     List<SeenItemModel>? seen,
     List<LikedItem>? likes,
     List<NotifiedItemModel>? notifications,
     List<QuickAddItemModel>? quickAdd,
     Map<String, List<MediaListItem>>? lists,
  }) : seen = seen ?? [],
       likes = likes ?? [],
       notifications = notifications ?? [],
       quickAdd = quickAdd ?? [],
       lists = lists ?? {};

  List<int> toZipBytes() {
    final archive = Archive();

    // meta.csv
    final metaCsv = csv.encode(<List<dynamic>>[
      ['version', 'exportedAt', 'source'],
      [version, exportedAt.toIso8601String(), source ?? ''],
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
          s.title,
          s.posterPath ?? '',
          s.seenDate.toIso8601String(),
          s.seasonNumber ?? '',
          s.episodeNumber ?? '',
          s.runtime ?? '',
          s.genres?.join('|') ?? '',
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
        likesRows.add([l.tmdbId, l.type, l.title]);
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
          n.title,
          n.posterPath ?? '',
          n.releaseDate?.toIso8601String() ?? '',
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
            item.listName,
            item.id,
            item.type,
            item.title,
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
          q.insertedAt.toIso8601String(),
          q.airDate?.toIso8601String() ?? '',
          q.title ?? '',
          q.posterPath ?? '',
        ]);
      }
      final qaCsv = csv.encode(qaRows);
      archive.addFile(
        ArchiveFile('quickadd.csv', qaCsv.length, utf8.encode(qaCsv)),
      );
    }

    return ZipEncoder().encode(archive);
  }

  static ExportEnvelope fromZipBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    int version = 1;
    DateTime exportedAt = DateTime.now();
    String? source;
    final List<SeenItemModel> seen = [];
    final List<LikedItem> likes = [];
    final List<NotifiedItemModel> notifications = [];
    final List<QuickAddItemModel> quickAdd = [];
    final Map<String, List<MediaListItem>> lists = {};

    for (final file in archive) {
      if (!file.isFile) continue;
      final filename = file.name;
      final content = utf8.decode(file.content as List<int>);
      final rows = csv.decode(content);
      if (rows.isEmpty) continue;

      final headers = rows.first.map((e) => e.toString().trim()).toList();

      if (filename == 'meta.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            if (headers[j] == 'version' && val is num) version = val.toInt();
            if (headers[j] == 'exportedAt')
              exportedAt = DateTime.tryParse(val.toString()) ?? exportedAt;
            if (headers[j] == 'source' && val.toString().isNotEmpty)
              source = val.toString();
          }
        }
      } else if (filename == 'seen.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          int tmdbId = 0;
          String type = 'movie';
          String title = 'Unknown';
          String? posterPath;
          DateTime seenDate = DateTime.now();
          int? seasonNumber;
          int? episodeNumber;
          int? runtime;
          List<String>? genres;

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            final valStr = val.toString().trim();
            if (valStr.isEmpty && headers[j] != 'type' && headers[j] != 'title')
              continue;

            switch (headers[j]) {
              case 'tmdbId':
                if (val is num)
                  tmdbId = val.toInt();
                else
                  tmdbId = int.tryParse(valStr) ?? 0;
                break;
              case 'type':
                type = valStr;
                break;
              case 'title':
                title = valStr;
                break;
              case 'posterPath':
                posterPath = valStr;
                break;
              case 'seenDate':
                seenDate = DateTime.tryParse(valStr) ?? seenDate;
                break;
              case 'seasonNumber':
                seasonNumber = int.tryParse(valStr);
                break;
              case 'episodeNumber':
                episodeNumber = int.tryParse(valStr);
                break;
              case 'runtime':
                runtime = int.tryParse(valStr);
                break;
              case 'genres':
                genres = valStr.split('|');
                break;
            }
          }
          seen.add(
            SeenItemModel(
              tmdbId: tmdbId,
              type: type,
              title: title,
              posterPath: posterPath,
              seenDate: seenDate,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
              runtime: runtime,
              genres: genres,
            ),
          );
        }
      } else if (filename == 'likes.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          int tmdbId = 0;
          String type = 'movie';
          String title = 'Unknown';

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            final valStr = val.toString().trim();
            switch (headers[j]) {
              case 'tmdbId':
                if (val is num)
                  tmdbId = val.toInt();
                else
                  tmdbId = int.tryParse(valStr) ?? 0;
                break;
              case 'type':
                type = valStr;
                break;
              case 'title':
                title = valStr;
                break;
            }
          }
          likes.add(LikedItem(tmdbId: tmdbId, type: type, title: title));
        }
      } else if (filename == 'notifications.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          int tmdbId = 0;
          String type = 'movie';
          String title = 'Unknown';
          String? posterPath;
          DateTime? releaseDate;
          int? seasonNumber;
          int? episodeNumber;
          bool autoNotify = false;

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            final valStr = val.toString().trim();
            if (valStr.isEmpty &&
                headers[j] != 'type' &&
                headers[j] != 'title' &&
                headers[j] != 'autoNotify')
              continue;

            switch (headers[j]) {
              case 'tmdbId':
                if (val is num)
                  tmdbId = val.toInt();
                else
                  tmdbId = int.tryParse(valStr) ?? 0;
                break;
              case 'type':
                type = valStr;
                break;
              case 'title':
                title = valStr;
                break;
              case 'posterPath':
                posterPath = valStr;
                break;
              case 'releaseDate':
                releaseDate = DateTime.tryParse(valStr);
                break;
              case 'seasonNumber':
                seasonNumber = int.tryParse(valStr);
                break;
              case 'episodeNumber':
                episodeNumber = int.tryParse(valStr);
                break;
              case 'autoNotify':
                autoNotify = valStr.toLowerCase() == 'true';
                break;
            }
          }
          notifications.add(
            NotifiedItemModel(
              tmdbId: tmdbId,
              type: type,
              title: title,
              posterPath: posterPath,
              releaseDate: releaseDate,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
              autoNotify: autoNotify,
            ),
          );
        }
      } else if (filename == 'quickadd.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          int tmdbId = 0;
          String type = 'tv';
          int? seasonNumber;
          int? episodeNumber;
          DateTime insertedAt = DateTime.now();
          DateTime? airDate;
          String? title;
          String? posterPath;

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            final valStr = val.toString().trim();
            if (valStr.isEmpty && headers[j] != 'type') continue;
            switch (headers[j]) {
              case 'tmdbId':
                if (val is num)
                  tmdbId = val.toInt();
                else
                  tmdbId = int.tryParse(valStr) ?? 0;
                break;
              case 'type':
                type = valStr;
                break;
              case 'seasonNumber':
                seasonNumber = int.tryParse(valStr);
                break;
              case 'episodeNumber':
                episodeNumber = int.tryParse(valStr);
                break;
              case 'insertedAt':
                insertedAt = DateTime.tryParse(valStr) ?? insertedAt;
                break;
              case 'airDate':
                airDate = DateTime.tryParse(valStr);
                break;
              case 'title':
                title = valStr.isNotEmpty ? valStr : null;
                break;
              case 'posterPath':
                posterPath = valStr.isNotEmpty ? valStr : null;
                break;
            }
          }

          quickAdd.add(
            QuickAddItemModel(
              tmdbId: tmdbId,
              type: type,
              seasonNumber: seasonNumber,
              episodeNumber: episodeNumber,
              insertedAt: insertedAt,
              airDate: airDate,
              title: title,
              posterPath: posterPath,
            ),
          );
        }
      } else if (filename == 'lists.csv') {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          String listName = 'watchlist';
          int tmdbId = 0;
          String type = 'movie';
          String title = 'Unknown';
          int position = 0;

          for (int j = 0; j < headers.length && j < row.length; j++) {
            final val = row[j];
            final valStr = val.toString().trim();
            switch (headers[j]) {
              case 'listName':
                listName = valStr;
                break;
              case 'tmdbId':
                if (val is num)
                  tmdbId = val.toInt();
                else
                  tmdbId = int.tryParse(valStr) ?? 0;
                break;
              case 'type':
                type = valStr;
                break;
              case 'title':
                title = valStr;
                break;
              case 'position':
                if (val is num)
                  position = val.toInt();
                else
                  position = int.tryParse(valStr) ?? 0;
                break;
            }
          }
          lists
              .putIfAbsent(listName, () => [])
              .add(
                MediaListItem(
                  id: tmdbId,
                  type: type,
                  title: title,
                  listName: listName,
                  position: position,
                ),
              );
        }
      }
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
    );
  }
}
