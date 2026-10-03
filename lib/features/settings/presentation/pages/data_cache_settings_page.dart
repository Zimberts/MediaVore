import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';

import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DataCacheSettingsPage extends StatelessWidget {
  const DataCacheSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug trace for widget tests
    // ignore: avoid_print
    print('DataCacheSettingsPage.build');
    final provider = context.watch<SearchProvider>();
    final achievementProvider = context.watch<AchievementProvider>();
    final settings = context.watch<SettingsProvider>();
    final isCacheLoading = provider.isCacheLoading;
    final isDbSizeLoading = provider.isDbSizeLoading;
    final isImporting = provider.isImporting;
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
                        onPressed: () => provider.updateCacheSize(),
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
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(context.l10n.dataFillCache),
                subtitle: Text(context.l10n.dataFillCacheSubtitle),
                enabled: !isCacheLoading,
                onTap: () => provider.fillCache(),
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
                        onPressed: () => provider.updateSeenDbSize(),
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
                  action: () => provider.refetchMissingData(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: Text(context.l10n.dataExportAll),
                subtitle: Text(context.l10n.dataExportAllSubtitle),
                onTap: () async {
                  final zipBytes = await provider.exportAllData();
                  if (!context.mounted) return;
                  final tempDir = await getTemporaryDirectory();
                  final fileName =
                      'mediavore_export_${DateTime.now().millisecondsSinceEpoch}.mdv';
                  final tempFile = File('${tempDir.path}/$fileName');
                  await tempFile.writeAsBytes(zipBytes);
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      builder: (saveSheetContext) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
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
                                Navigator.pop(saveSheetContext);
                                await Share.shareXFiles([
                                  XFile(
                                    tempFile.path,
                                    mimeType: 'application/octet-stream',
                                  ),
                                ], text: context.l10n.dataExportShareText);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: Text(context.l10n.dataImportAll),
                subtitle: Text(context.l10n.dataImportAllSubtitle),
                onTap: () => _importAllDataWithPreview(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: Text(context.l10n.dataPopulateQuickAdd),
                subtitle: Text(context.l10n.dataPopulateQuickAddSubtitle),
                enabled: !isImporting,
                onTap: () => _confirmAction(
                  context,
                  title: context.l10n.dataPopulateQuickAddTitle,
                  message: context.l10n.dataPopulateQuickAddMessage,
                  action: () async {
                    // Clear existing quick-add entries so the populate action
                    // fully reflects current seen history.
                    await provider.clearQuickAddItems();
                    await provider.populateQuickAddFromSeenHistory();
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
                onChanged: (val) => settings.setNotificationCenterDebug(val),
              ),
            ],
          ),
          if (isCacheLoading || isDbSizeLoading || isImporting)
            Container(
              color: colors.placeholder.withValues(alpha: 0.1),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: isImporting ? provider.importProgress : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isImporting
                              ? provider.importStatus
                              : context.l10n.commonProcessing,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  String get _defaultPath => '/storage/emulated/0/Download/MediaVore';

  Future<void> _saveFileToDevice(
    BuildContext context,
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: context.l10n.dataSaveExportDialog,
        fileName: fileName,
        initialDirectory: Platform.isAndroid ? _defaultPath : null,
        bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.dataFileSaved)));
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
    SearchProvider provider,
  ) async {
    // Debug trace for widget tests
    // ignore: avoid_print
    print('_importAllDataWithPreview called');
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      initialDirectory: Platform.isAndroid ? _defaultPath : null,
    );

    if (!context.mounted) return;

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!path.toLowerCase().endsWith('.mdv') &&
          !path.toLowerCase().endsWith('.zip')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.dataInvalidFile)));
        return;
      }

      final file = File(path);
      final bytes = await file.readAsBytes();

      try {
        // ignore: avoid_print
        print('File picked, reading content');

        // Use serializer to normalize and validate
        final ExportEnvelope envelope = ExportEnvelope.fromZipBytes(bytes);

        if (!context.mounted) return;

        final seenCount = envelope.seen.length;
        final likesCount = envelope.likes.length;
        final notCount = envelope.notifications.length;
        final listsCount = envelope.lists.length;

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.dataImportPreviewTitle),
            content: Text(
              context.l10n.dataImportPreviewMessage(
                seenCount,
                likesCount,
                notCount,
                listsCount,
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
                  await provider.importAllData(bytes, mode: ImportMode.append);
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
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.dataImportFailed)),
          );
        }
      }
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
    showDialog(
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
