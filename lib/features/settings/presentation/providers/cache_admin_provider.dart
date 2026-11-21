import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';

/// Cache and storage actions of the data settings page, offered by
/// [CacheAdminProvider] and, as a facade over it, by `SearchProvider`.
abstract interface class CacheAdminActions {
  int get cacheSize;
  int get seenDbSize;
  bool get isCacheLoading;
  bool get isDbSizeLoading;
  bool get isImporting;
  double get importProgress;
  String get importStatus;
  ValueListenable<CacheWarmupProgress?> get cacheWarmupProgress;

  Future<void> updateCacheSize();
  Future<void> updateSeenDbSize();
  Future<void> clearCache({required bool complete});
  Future<void> fillCache();
  void cancelCacheFill();
  Future<void> refetchMissingData();
  Future<List<int>> exportAllData();
  Future<void> importAllData(List<int> zipBytes, {ImportMode mode});
}

/// Provider dedicated to local TMDB cache and database storage administration.
class CacheAdminProvider with ChangeNotifier implements CacheAdminActions {
  CacheAdminProvider(this.repository, {this.localeService}) {
    unawaited(init());
  }

  final MediaRepository repository;
  final LocaleService? localeService;

  int _cacheSize = 0;
  int _seenDbSize = 0;
  bool _isCacheLoading = false;
  bool _isDbSizeLoading = false;
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _importStatus = '';

  @override
  int get cacheSize => _cacheSize;
  @override
  int get seenDbSize => _seenDbSize;
  @override
  bool get isCacheLoading => _isCacheLoading;
  @override
  bool get isDbSizeLoading => _isDbSizeLoading;
  @override
  bool get isImporting => _isImporting;
  @override
  double get importProgress => _importProgress;
  @override
  String get importStatus => _importStatus;
  @override
  ValueListenable<CacheWarmupProgress?> get cacheWarmupProgress =>
      repository.cacheWarmupProgress;

  @override
  void cancelCacheFill() => repository.cancelCacheWarmup();

  AppLocalizations get _l10n => lookupAppLocalizations(
    (localeService?.current ?? fallbackAppLanguage).locale,
  );

  Future<void> init() async {
    await updateCacheSize();
    await updateSeenDbSize();
  }

  @override
  Future<void> updateCacheSize() async {
    _isCacheLoading = true;
    notifyListeners();
    _cacheSize = await repository.getCacheSize();
    _isCacheLoading = false;
    notifyListeners();
  }

  @override
  Future<void> updateSeenDbSize() async {
    _isDbSizeLoading = true;
    notifyListeners();
    _seenDbSize = await repository.getSeenDbSize();
    _isDbSizeLoading = false;
    notifyListeners();
  }

  @override
  Future<void> clearCache({required bool complete}) async {
    _isCacheLoading = true;
    notifyListeners();
    await repository.clearCache(complete: complete);
    await updateCacheSize();
    _isCacheLoading = false;
    notifyListeners();
  }

  @override
  Future<void> fillCache() async {
    _isCacheLoading = true;
    notifyListeners();
    await repository.fillCache();
    await updateCacheSize();
    _isCacheLoading = false;
    notifyListeners();
  }

  @override
  Future<List<int>> exportAllData() {
    return repository.exportAllData();
  }

  Future<void> clearQuickAddItems() async {
    await repository.clearQuickAddItems();
  }

  Future<void> populateQuickAddFromSeenHistory() async {
    await repository.populateQuickAddFromSeenHistory();
  }

  @override
  Future<void> importAllData(
    List<int> zipBytes, {
    ImportMode mode = ImportMode.append,
  }) async {
    _isImporting = true;
    _importProgress = 0.0;
    _importStatus = _l10n.progressImportingAll;
    notifyListeners();

    try {
      await repository.importAllData(
        zipBytes,
        mode: mode,
        onProgress: (p, s) {
          _importProgress = p;
          _importStatus = s;
          notifyListeners();
        },
      );

      _importProgress = 1.0;
      _importStatus = _l10n.progressDone;
    } catch (e) {
      _importStatus = _l10n.progressError('$e');
    } finally {
      await updateCacheSize();
      await updateSeenDbSize();
      _isImporting = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refetchMissingData() async {
    _isImporting = true;
    _importProgress = 0.0;
    _importStatus = _l10n.progressRefetchingRuntimes;
    notifyListeners();

    try {
      final seenItems = await repository.getSeenItems();
      final itemsToUpdate = seenItems
          .where((i) => i.id != null && (i.runtime == null || i.runtime == 0))
          .toList();

      int processed = 0;
      for (final item in itemsToUpdate) {
        _importProgress = processed / itemsToUpdate.length;
        _importStatus = _l10n.progressRefetchingItem(item.title);
        notifyListeners();

        try {
          final details = await repository.getMediaDetails(
            item.tmdbId,
            type: item.type,
          );
          final runtime = details.item.runtime;
          if (runtime != null && runtime > 0) {
            final updated = item.copyWith(runtime: runtime);
            await repository.updateSeenEntry(updated);
          }
        } catch (e) {
          debugPrint(
            '[CacheAdminProvider] refetch runtime for ${item.title} failed: $e',
          );
        }

        processed++;
      }

      _importProgress = 1.0;
      _importStatus = _l10n.progressDone;
    } catch (e) {
      _importStatus = _l10n.progressError('$e');
    } finally {
      await updateSeenDbSize();
      _isImporting = false;
      notifyListeners();
    }
  }
}
