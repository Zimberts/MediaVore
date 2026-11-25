import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/export_file_name.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DataCacheSettingsPage extends StatefulWidget {
  const DataCacheSettingsPage({super.key});

  /// "Export all data" tile.
  static const Key exportKey = Key('data_export_all');

  /// "Save to device" choice of the export sheet.
  static const Key saveToDeviceKey = Key('data_export_save_to_device');

  /// "Import all data" tile.
  static const Key importKey = Key('data_import_all');

  /// "Replace" choice of the import preview.
  static const Key importReplaceKey = Key('data_import_replace');

  /// Confirmation of the replacing import.
  static const Key replaceConfirmKey = Key('data_import_replace_confirm');

  @override
  State<DataCacheSettingsPage> createState() => _DataCacheSettingsPageState();
}

class _DataCacheSettingsPageState extends State<DataCacheSettingsPage> {
  bool _isExporting = false;
  bool _isReadingBackup = false;

  @override
  Widget build(BuildContext context) {
    final cacheProvider = context.watch<CacheAdminProvider?>();
    final searchProvider = cacheProvider == null
        ? context.watch<SearchProvider>()
        : null;
    final CacheAdminActions provider = cacheProvider ?? searchProvider!;
    // Imports and refetches rewrite the user's data: they go through
    // SearchProvider, which reloads every screen afterwards. The bare
    // CacheAdminProvider would leave them stale until a restart.
    final userData = context.read<SearchProvider>();
    final achievementProvider = context.watch<AchievementProvider>();
    final settings = context.watch<SettingsProvider>();
    final isCacheLoading = provider.isCacheLoading;
    final isDbSizeLoading = provider.isDbSizeLoading;
    final isImporting = provider.isImporting;
    final isBusy =
        isCacheLoading ||
        isDbSizeLoading ||
        isImporting ||
        _isExporting ||
        _isReadingBackup;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsStorage)),
      body: Stack(
        children: [
          ListView(
            children: [
              _SectionHeader(title: context.l10n.dataSectionCache),
              ListTile(
                title: Text(context.l10n.dataCacheSize),
                subtitle: Text(_formatBytes(provider.cacheSize)),
                trailing: isCacheLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: context.l10n.commonRefresh,
                        onPressed: provider.updateCacheSize,
                      ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: Text(context.l10n.dataCleanupCache),
                subtitle: Text(context.l10n.dataCleanupCacheSubtitle),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataCleanupCache,
                  message: context.l10n.dataCleanupCacheMessage,
                  action: () => provider.clearCache(complete: false),
                ),
              ),
              ValueListenableBuilder<CacheWarmupProgress?>(
                valueListenable: provider.cacheWarmupProgress,
                builder: (context, progress, _) {
                  if (progress == null) {
                    return ListTile(
                      leading: const Icon(Icons.download),
                      title: Text(context.l10n.dataFillCache),
                      subtitle: Text(context.l10n.dataFillCacheSubtitle),
                      enabled: !isCacheLoading,
                      onTap: () async {
                        await provider.fillCache();
                        if (context.mounted) {
                          await achievementProvider.refresh();
                        }
                      },
                    );
                  }
                  final value = progress.total > 0
                      ? progress.done / progress.total
                      : null;
                  return ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(
                      context.l10n.dataCachingTitles(
                        progress.done,
                        progress.total,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(value: value),
                    ),
                    trailing: TextButton(
                      onPressed: provider.cancelCacheFill,
                      child: Text(context.l10n.commonCancel),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: colors.error),
                title: Text(
                  context.l10n.dataWipeCache,
                  style: TextStyle(color: colors.error),
                ),
                subtitle: Text(context.l10n.dataWipeCacheSubtitle),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataWipeCache,
                  message: context.l10n.dataWipeCacheMessage,
                  action: () => provider.clearCache(complete: true),
                ),
              ),
              const Divider(),
              _SectionHeader(title: context.l10n.dataSectionData),
              ListTile(
                title: Text(context.l10n.dataSeenDbSize),
                subtitle: Text(_formatBytes(provider.seenDbSize)),
                trailing: isDbSizeLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: context.l10n.commonRefresh,
                        onPressed: provider.updateSeenDbSize,
                      ),
              ),
              ListTile(
                leading: const Icon(Icons.update),
                title: Text(context.l10n.dataRefetchRuntimes),
                subtitle: Text(context.l10n.dataRefetchRuntimesSubtitle),
                enabled: !isImporting,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataRefetchTitle,
                  message: context.l10n.dataRefetchMessage,
                  action: userData.refetchMissingData,
                ),
              ),
              ListTile(
                key: DataCacheSettingsPage.exportKey,
                leading: const Icon(Icons.cloud_upload),
                title: Text(context.l10n.dataExportAll),
                subtitle: Text(context.l10n.dataExportAllSubtitle),
                enabled: !isBusy,
                onTap: () async {
                  setState(() => _isExporting = true);
                  try {
                    final zipBytes = await provider.exportAllData();
                    if (!context.mounted) return;
                    final tempDir = await getTemporaryDirectory();
                    final fileName = exportFileName(DateTime.now());
                    final tempFile = File('${tempDir.path}/$fileName');
                    await tempFile.writeAsBytes(zipBytes);
                    if (context.mounted) {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (saveSheetContext) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  key: DataCacheSettingsPage.saveToDeviceKey,
                                  leading: const Icon(Icons.save_alt),
                                  title: Text(context.l10n.dataSaveToDevice),
                                  onTap: () async {
                                    Navigator.pop(saveSheetContext);
                                    await _saveFileToDevice(
                                      context,
                                      zipBytes,
                                      fileName,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: Text(context.l10n.dataShareViaSystem),
                                  onTap: () async {
                                    final shareText =
                                        context.l10n.dataExportShareText;
                                    Navigator.pop(saveSheetContext);
                                    final shared = await SharePlus.instance
                                        .share(
                                          ShareParams(
                                            files: [
                                              XFile(
                                                tempFile.path,
                                                mimeType:
                                                    'application/octet-stream',
                                              ),
                                            ],
                                            text: shareText,
                                          ),
                                        );
                                    // `unavailable`: the platform cannot tell.
                                    if (shared.status !=
                                        ShareResultStatus.dismissed) {
                                      await achievementProvider.recordExport();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isExporting = false);
                    }
                  }
                },
              ),
              ListTile(
                key: DataCacheSettingsPage.importKey,
                leading: const Icon(Icons.file_download),
                title: Text(context.l10n.dataImportAll),
                subtitle: Text(context.l10n.dataImportAllSubtitle),
                enabled: !isBusy,
                onTap: () => _importAllDataWithPreview(context, userData),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: Text(context.l10n.dataPopulateQuickAdd),
                subtitle: Text(context.l10n.dataPopulateQuickAddSubtitle),
                enabled: !isBusy,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataPopulateQuickAddTitle,
                  message: context.l10n.dataPopulateQuickAddMessage,
                  action: () async {
                    // Clear existing quick-add entries so the populate action
                    // fully reflects current seen history.
                    final search = context.read<SearchProvider>();
                    await search.clearQuickAddItems();
                    await search.populateQuickAddFromSeenHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.dataPopulateQuickAddDone),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(),
              _SectionHeader(title: context.l10n.dataSectionAchievements),
              ListTile(
                leading: Icon(Icons.stars_outlined, color: colors.error),
                title: Text(
                  context.l10n.dataClearAchievements,
                  style: TextStyle(color: colors.error),
                ),
                subtitle: Text(context.l10n.dataClearAchievementsSubtitle),
                enabled: !isBusy,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataClearAchievementsTitle,
                  message: context.l10n.dataClearAchievementsMessage,
                  action: () async {
                    await achievementProvider.clearAchievements();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.dataClearAchievementsDone),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(),
              _SectionHeader(title: context.l10n.dataSectionDebug),
              SwitchListTile(
                title: Text(context.l10n.dataNotificationDebug),
                subtitle: Text(context.l10n.dataNotificationDebugSubtitle),
                value: settings.notificationCenterDebug,
                onChanged: settings.setNotificationCenterDebug,
              ),
            ],
          ),
          if (isBusy)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: colors.placeholder.withValues(alpha: 0.1),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: isImporting
                                  ? provider.importProgress
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isImporting
                                  ? provider.importStatus
                                  : _isExporting
                                  ? context.l10n.dataExporting
                                  : _isReadingBackup
                                  ? context.l10n.dataReadingBackup
                                  : context.l10n.commonProcessing,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isImporting)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '${(provider.importProgress * 100).toInt()}%',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  String get _defaultPath => '/storage/emulated/0/Download/MediaVore';

  Future<void> _saveFileToDevice(
    BuildContext context,
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final result = await FilePicker.saveFile(
        dialogTitle: context.l10n.dataSaveExportDialog,
        fileName: fileName,
        initialDirectory: Platform.isAndroid ? _defaultPath : null,
        bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.dataFileSaved)));
        await context.read<AchievementProvider>().recordExport();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dataSaveFailed('$e'))),
        );
      }
    }
  }

  Future<void> _importAllDataWithPreview(
    BuildContext context,
    CacheAdminActions provider,
  ) async {
    final picked = await FilePicker.pickFile(
      initialDirectory: Platform.isAndroid ? _defaultPath : null,
    );

    if (!context.mounted) return;

    if (picked != null) {
      // file_picker >= 12 may return a content:// URI (no local path) on
      // Android: check the name and read through the PlatformFile.
      final name = picked.name.toLowerCase();
      if (!name.endsWith('.mdv') && !name.endsWith('.zip')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.dataInvalidFile)));
        return;
      }

      final List<int> bytes;
      final ExportEnvelope envelope;
      try {
        setState(() => _isReadingBackup = true);
        bytes = await picked.readAsBytes();
        if (!context.mounted) return;
        // Use serializer to normalize and validate on background isolate
        envelope = await ExportEnvelope.fromZipBytesAsync(bytes);
      } on ParsingException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.dataImportFailedReason(e.message)),
            ),
          );
        }
        return;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.dataImportFailed)),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _isReadingBackup = false);
        }
      }

      if (!context.mounted) return;

      final seenCount = envelope.seen.length;
      final likesCount = envelope.likes.length;
      final notCount = envelope.notifications.length;
      final listsCount = envelope.lists.length;
      final warnings = envelope.warnings;
      final warningsText = warnings.isEmpty
          ? ''
          : '\n${context.l10n.dataImportSkippedRows(warnings.length)}\n'
                '${warnings.take(5).join('\n')}'
                '${warnings.length > 5 ? '\n…' : ''}\n';

      unawaited(
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.dataImportPreviewTitle),
            content: Text(
              context.l10n.dataImportPreviewMessage(
                seenCount,
                likesCount,
                notCount,
                listsCount,
                warningsText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await provider.importAllData(bytes);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.dataImportedAppended),
                      ),
                    );
                  }
                },
                child: Text(context.l10n.dataAppend),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await provider.importAllData(bytes, mode: ImportMode.merge);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.dataImportedMerged)),
                    );
                  }
                },
                child: Text(context.l10n.dataMerge),
              ),
              TextButton(
                key: DataCacheSettingsPage.importReplaceKey,
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final confirmed = await _confirmReplace(context);
                  if (confirmed && context.mounted) {
                    await provider.importAllData(
                      bytes,
                      mode: ImportMode.replace,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.dataImportedReplaced),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  context.l10n.dataReplace,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<bool> _confirmReplace(BuildContext context) async {
    final colors = context.appColors;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.dataReplaceTitle),
            content: Text(context.l10n.dataReplaceMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                key: DataCacheSettingsPage.replaceConfirmKey,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  context.l10n.dataReplaceConfirm,
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await action();
            },
            child: Text(context.l10n.commonProceed),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
