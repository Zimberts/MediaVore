import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/media_details/data/datasources/manual_media_local_data_source.dart';
import 'package:mediavore/features/media_details/data/datasources/media_list_local_data_source.dart';
import 'package:mediavore/features/media_details/data/models/liked_item.dart';
import 'package:mediavore/features/media_details/data/models/manual_media_model.dart';
import 'package:mediavore/features/media_details/data/models/media_list_item.dart';
import 'package:mediavore/features/media_details/data/models/notified_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_item_model.dart';
import 'package:mediavore/features/media_details/data/models/quick_add_opt_out_model.dart';
import 'package:mediavore/features/media_details/data/models/seen_item_model.dart';
import 'package:mediavore/features/search/data/services/media_details_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Export of every user collection to an archive, and atomic import of one.
///
/// Part of `MediaRepositoryImpl`; callers are expected to have awaited the
/// repository's initialization.
class ImportExportService {
  final MediaListLocalDataSource localDataSource;
  final MediaDetailsService details;
  final ManualMediaLocalDataSource? manualMediaDataSource;

  /// Language of the progress messages; `null` uses the fallback language.
  final LocaleService? localeService;

  ImportExportService({
    required this.localDataSource,
    required this.details,
    this.manualMediaDataSource,
    this.localeService,
  });

  /// Strings for progress messages, in the current app language.
  AppLocalizations get _l10n => lookupAppLocalizations(
    (localeService?.current ?? fallbackAppLanguage).locale,
  );

  Future<List<int>> exportAllData() async {
    final seenModels = await localDataSource.getExportData();
    final likedModels = await localDataSource.getLikedItems();
    final notifiedModels = await localDataSource.getNotifiedItems();
    final quickAddModels = await localDataSource.getQuickAddItems();
    final optOutModels = await localDataSource.getOptOuts();
    final manualModels =
        await manualMediaDataSource?.getAllModels() ?? const [];

    final names = await localDataSource.getAllListNames();
    final Map<String, List<MediaListItem>> lists = {};
    for (final name in names) {
      lists[name] = await localDataSource.getListItems(name);
    }

    final envelope = ExportEnvelope(
      version: 1,
      exportedAt: DateTime.now(),
      seen: seenModels,
      likes: likedModels,
      notifications: notifiedModels,
      quickAdd: quickAddModels,
      lists: lists,
      optOuts: optOutModels,
      manualMedia: manualModels,
    );

    return envelope.toZipBytesAsync();
  }

  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
    void Function(double, String)? onProgress,
  }) async {
    final envelope = await ExportEnvelope.fromZipBytesAsync(zipBytes);

    // Network enrichment first (no DB writes), then a single transaction for
    // every collection: a failure at any stage leaves the database unchanged.
    final seenItems = await _enrichSeenData(
      envelope.seen,
      onProgress: (p, s) => onProgress?.call(p * 0.9, s),
    );

    onProgress?.call(0.9, _l10n.progressSavingEntries);
    final remapped = await _remapManualIdsIfNeeded(
      mode: mode,
      manualMedia: envelope.manualMedia,
      seen: seenItems,
      likes: envelope.likes,
      notifications: envelope.notifications,
      quickAdd: envelope.quickAdd,
      lists: envelope.lists,
      optOuts: envelope.optOuts,
    );

    await localDataSource.importAll(
      mode: mode,
      seen: remapped.seen,
      likes: remapped.likes,
      notifications: remapped.notifications,
      quickAdd: remapped.quickAdd,
      lists: remapped.lists,
      optOuts: remapped.optOuts,
      manualMedia: remapped.manualMedia,
    );
    await manualMediaDataSource?.syncCounter();
    onProgress?.call(1.0, _l10n.progressImportComplete);
  }

  Future<
    ({
      List<ManualMediaModel> manualMedia,
      List<SeenItemModel> seen,
      List<LikedItem> likes,
      List<NotifiedItemModel> notifications,
      List<QuickAddItemModel> quickAdd,
      Map<String, List<MediaListItem>> lists,
      List<QuickAddOptOutModel> optOuts,
    })
  >
  _remapManualIdsIfNeeded({
    required ImportMode mode,
    required List<ManualMediaModel> manualMedia,
    required List<SeenItemModel> seen,
    required List<LikedItem> likes,
    required List<NotifiedItemModel> notifications,
    required List<QuickAddItemModel> quickAdd,
    required Map<String, List<MediaListItem>> lists,
    required List<QuickAddOptOutModel> optOuts,
  }) async {
    if (mode == ImportMode.replace ||
        manualMedia.isEmpty ||
        manualMediaDataSource == null) {
      return (
        manualMedia: manualMedia,
        seen: seen,
        likes: likes,
        notifications: notifications,
        quickAdd: quickAdd,
        lists: lists,
        optOuts: optOuts,
      );
    }

    final existing = await manualMediaDataSource!.getAllModels();
    final existingIds = {for (final m in existing) m.localId};
    final idMap = <int, int>{};
    final remappedManual = <ManualMediaModel>[];

    for (final m in manualMedia) {
      if (existingIds.contains(m.localId)) {
        final newId = await manualMediaDataSource!.allocateNextId();
        idMap[m.localId] = newId;
        existingIds.add(newId);
        remappedManual.add(
          ManualMediaModel(
            localId: newId,
            kind: m.kind,
            title: m.title,
            originalTitle: m.originalTitle,
            overview: m.overview,
            releaseDate: m.releaseDate,
            runtime: m.runtime,
            seasons: m.seasons,
            posterPath: m.posterPath,
            genres: m.genres,
            originCountries: m.originCountries,
            sourceUrl: m.sourceUrl,
            sourceProvider: m.sourceProvider,
            createdAt: m.createdAt,
            updatedAt: m.updatedAt,
          ),
        );
      } else {
        existingIds.add(m.localId);
        remappedManual.add(m);
      }
    }

    if (idMap.isEmpty) {
      return (
        manualMedia: remappedManual,
        seen: seen,
        likes: likes,
        notifications: notifications,
        quickAdd: quickAdd,
        lists: lists,
        optOuts: optOuts,
      );
    }

    int remap(int id) => id < 0 ? (idMap[id] ?? id) : id;

    return (
      manualMedia: remappedManual,
      seen: [
        for (final s in seen)
          SeenItemModel(
            tmdbId: remap(s.tmdbId),
            type: s.type,
            title: s.title,
            posterPath: s.posterPath,
            seenDate: s.seenDate,
            seasonNumber: s.seasonNumber,
            episodeNumber: s.episodeNumber,
            runtime: s.runtime,
            genres: s.genres,
          ),
      ],
      likes: [
        for (final l in likes)
          LikedItem(tmdbId: remap(l.tmdbId), type: l.type, title: l.title),
      ],
      notifications: [
        for (final n in notifications)
          NotifiedItemModel(
            tmdbId: remap(n.tmdbId),
            type: n.type,
            title: n.title,
            posterPath: n.posterPath,
            releaseDate: n.releaseDate,
            seasonNumber: n.seasonNumber,
            episodeNumber: n.episodeNumber,
            runtime: n.runtime,
            autoNotify: n.autoNotify,
          ),
      ],
      quickAdd: [
        for (final q in quickAdd)
          QuickAddItemModel(
            tmdbId: remap(q.tmdbId),
            type: q.type,
            seasonNumber: q.seasonNumber,
            episodeNumber: q.episodeNumber,
            insertedAt: q.insertedAt,
            airDate: q.airDate,
            title: q.title,
            posterPath: q.posterPath,
          ),
      ],
      lists: {
        for (final entry in lists.entries)
          entry.key: [
            for (final item in entry.value)
              MediaListItem(
                id: remap(item.id),
                type: item.type,
                title: item.title,
                listName: item.listName,
                position: item.position,
              ),
          ],
      },
      optOuts: [
        for (final o in optOuts)
          QuickAddOptOutModel(
            tmdbId: remap(o.tmdbId),
            seasonNumber: o.seasonNumber,
            episodeNumber: o.episodeNumber,
            optedOutAt: o.optedOutAt,
          ),
      ],
    );
  }

  /// Fills missing runtime/genres from TMDB. Network only: writes nothing, so
  /// it can run before the import transaction.
  Future<List<SeenItemModel>> _enrichSeenData(
    List<SeenItemModel> data, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final List<SeenItemModel> items = [];
    final total = data.length;

    // One lookup per show/season for the whole import, failures included:
    // a CSV of N episodes of one show must not trigger N network attempts.
    final Map<String, Future<MediaDetails?>> detailsByKey = {};
    final Map<String, Future<Map<String, dynamic>?>> seasonsByKey = {};
    Future<MediaDetails?> detailsOnce(int id, MediaType type) =>
        detailsByKey.putIfAbsent(
          '${type.name}:$id',
          () => details
              .getMediaDetails(id, type: type)
              .then<MediaDetails?>((d) => d, onError: (_) => null),
        );
    Future<Map<String, dynamic>?> seasonOnce(int id, int season) =>
        seasonsByKey.putIfAbsent(
          '$id:$season',
          () => details
              .getSeasonDetails(id, season)
              .then<Map<String, dynamic>?>((d) => d, onError: (_) => null),
        );

    for (int i = 0; i < total; i++) {
      final model = data[i];
      final tmdbId = model.tmdbId;
      final typeStr = model.type;
      final type = typeStr == 'movie' ? MediaType.movie : MediaType.tv;
      final seasonNumber = model.seasonNumber;
      final episodeNumber = model.episodeNumber;
      final title = model.title;

      if (onProgress != null) {
        onProgress(i / total, _l10n.progressProcessingItem(title));
      }

      if (tmdbId < 0) {
        items.add(model);
        continue;
      }

      final enriched = await details.resolveRuntimeAndGenres(
        tmdbId: tmdbId,
        type: type,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        runtime: model.runtime,
        genres: model.genres,
        fetchDetails: detailsOnce,
        fetchSeason: seasonOnce,
      );

      items.add(
        SeenItemModel(
          tmdbId: tmdbId,
          type: typeStr,
          title: title,
          posterPath: model.posterPath,
          seenDate: model.seenDate,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          runtime: enriched.runtime,
          genres: enriched.genres,
        ),
      );
    }

    return items;
  }
}
