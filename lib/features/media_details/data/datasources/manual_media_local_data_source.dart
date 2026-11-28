import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/constants/storage_keys.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/features/media_details/data/models/manual_media_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Isar persistence and negative-ID allocator for [ManualMediaModel].
@lazySingleton
class ManualMediaLocalDataSource {
  final Isar _isar;
  final SharedPreferences _prefs;

  ManualMediaLocalDataSource(this._isar, this._prefs);

  /// Allocates the next unused negative local ID (`-1, -2, ...`).
  ///
  /// Combines the persisted counter in [SharedPreferences] with the minimum
  /// existing `localId` in Isar so IDs are never reused even after deletions or
  /// imports.
  Future<int> allocateNextId() async {
    final stored = _prefs.getInt(StorageKeys.manualMediaNextIdKey) ?? -1;
    final lowestRow = await _isar.manualMediaModels
        .where()
        .sortByLocalId()
        .findFirst();
    final minExisting = lowestRow != null ? lowestRow.localId - 1 : -1;
    final nextId = stored < minExisting ? stored : minExisting;
    final safeId = nextId >= 0 ? -1 : nextId;
    await _prefs.setInt(StorageKeys.manualMediaNextIdKey, safeId - 1);
    return safeId;
  }

  /// Ensures the persisted counter stays strictly below all existing local IDs.
  Future<void> syncCounter() async {
    final lowestRow = await _isar.manualMediaModels
        .where()
        .sortByLocalId()
        .findFirst();
    if (lowestRow == null) return;
    final minNext = lowestRow.localId - 1;
    final stored = _prefs.getInt(StorageKeys.manualMediaNextIdKey) ?? -1;
    if (minNext < stored) {
      await _prefs.setInt(StorageKeys.manualMediaNextIdKey, minNext);
    }
  }

  Future<ManualMedia> createManualMedia({
    required ManualMediaKind kind,
    required String title,
    String? originalTitle,
    String? overview,
    String? releaseDate,
    int? runtime,
    List<int>? seasons,
    String? posterPath,
    List<String>? genres,
    List<String>? originCountries,
    String? sourceUrl,
    String? sourceProvider,
  }) async {
    final localId = await allocateNextId();
    final now = DateTime.now();
    final model = ManualMediaModel(
      localId: localId,
      kind: kind,
      title: title,
      originalTitle: originalTitle,
      overview: overview,
      releaseDate: releaseDate,
      runtime: runtime,
      seasons: seasons,
      posterPath: posterPath,
      genres: genres,
      originCountries: originCountries,
      sourceUrl: sourceUrl,
      sourceProvider: sourceProvider,
      createdAt: now,
      updatedAt: now,
    );
    await _isar.writeTxn(() async {
      await _isar.manualMediaModels.putByLocalId(model);
    });
    return model.toEntity();
  }

  Future<ManualMedia> updateManualMedia(ManualMedia entity) async {
    final existing = await _isar.manualMediaModels
        .where()
        .localIdEqualTo(entity.localId)
        .findFirst();
    final now = DateTime.now();
    final model = ManualMediaModel(
      isarId: existing?.isarId,
      localId: entity.localId,
      kind: entity.kind,
      title: entity.title,
      originalTitle: entity.originalTitle,
      overview: entity.overview,
      releaseDate: entity.releaseDate,
      runtime: entity.runtime,
      seasons: entity.seasons,
      posterPath: entity.posterPath,
      genres: entity.genres,
      originCountries: entity.originCountries,
      sourceUrl: entity.sourceUrl,
      sourceProvider: entity.sourceProvider,
      createdAt: existing?.createdAt ?? entity.createdAt,
      updatedAt: now,
    );
    await _isar.writeTxn(() async {
      await _isar.manualMediaModels.putByLocalId(model);
    });
    return model.toEntity();
  }

  Future<ManualMedia?> getByLocalId(int localId) async {
    if (localId >= 0) return null;
    final model = await _isar.manualMediaModels
        .where()
        .localIdEqualTo(localId)
        .findFirst();
    return model?.toEntity();
  }

  Future<List<ManualMedia>> getAll() async {
    final models = await _isar.manualMediaModels.where().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<List<ManualMediaModel>> getAllModels() =>
      _isar.manualMediaModels.where().findAll();

  Future<void> deleteByLocalId(int localId) async {
    final existing = await _isar.manualMediaModels
        .where()
        .localIdEqualTo(localId)
        .findFirst();
    final posterPath = existing?.posterPath;
    await _isar.writeTxn(() async {
      await _isar.manualMediaModels.deleteByLocalId(localId);
    });
    if (posterPath != null && posterPath.contains('manual_posters')) {
      try {
        final file = File(posterPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup of local poster file.
      }
    }
  }

  Future<void> deleteAll() async {
    await _isar.writeTxn(() async {
      await _isar.manualMediaModels.clear();
    });
  }

  Future<void> putAllModels(List<ManualMediaModel> models) async {
    if (models.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.manualMediaModels.putAllByLocalId(models);
    });
    await syncCounter();
  }
}
