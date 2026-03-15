import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
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
    final isCacheLoading = provider.isCacheLoading;
    final isDbSizeLoading = provider.isDbSizeLoading;
    final isImporting = provider.isImporting;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Storage & Data')),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionHeader(title: 'Cache Management'),
              ListTile(
                title: const Text('Cache Size'),
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
                title: const Text('Cleanup Cache'),
                subtitle: const Text(
                  'Remove old, unused search results and details.',
                ),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: 'Cleanup Cache',
                  message:
                      'This will remove search results and details older than 60 days that are not in your lists.',
                  action: () => provider.clearCache(complete: false),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Fill Cache'),
                subtitle: const Text(
                  'Pre-cache all items in your lists and recent history for offline use.',
                ),
                enabled: !isCacheLoading,
                onTap: () => provider.fillCache(),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: colors.error),
                title: Text(
                  'Wipe All Cache',
                  style: TextStyle(color: colors.error),
                ),
                subtitle: const Text('Delete everything from cache.'),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: 'Wipe All Cache',
                  message:
                      'This will delete ALL cached posters and details. You will need internet to see them again.',
                  action: () => provider.clearCache(complete: true),
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Data Management'),
              ListTile(
                title: const Text('Seen Database Size'),
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
                title: const Text('Refetch Media Runtimes'),
                subtitle: const Text(
                  'Fetch missing runtimes and genres for your history.',
                ),
                enabled: !isImporting,
                onTap: () => _confirmAction(
                  context,
                  title: 'Refetch Data',
                  message:
                      'This will check your seen history and fetch any missing runtimes or genres from TMDb. This might take a while.',
                  action: () => provider.refetchMissingData(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload),
                title: const Text('Export All Data'),
                subtitle: const Text(
                  'Export seen, likes, notifications and lists as a single ZIP file.',
                ),
                onTap: () async {
                  final zipBytes = await provider.exportAllData();
                  if (!context.mounted) return;
                  final tempDir = await getTemporaryDirectory();
                  final fileName =
                      'mediavore_export_${DateTime.now().millisecondsSinceEpoch}.zip';
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
                              title: const Text('Save to device'),
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
                              title: const Text('Share via System'),
                              onTap: () async {
                                Navigator.pop(saveSheetContext);
                                await Share.shareXFiles([
                                  XFile(
                                    tempFile.path,
                                    mimeType: 'application/zip',
                                  ),
                                ], text: 'MediaVore Export');
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
                title: const Text('Import All Data'),
                subtitle: const Text(
                  'Import seen, likes, notifications and lists from an export ZIP.',
                ),
                onTap: () => _importAllDataWithPreview(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Populate Quick Add from Seen History'),
                subtitle: const Text(
                  'Compute next episodes from your seen history and save them to Quick Add.',
                ),
                enabled: !isImporting,
                onTap: () => _confirmAction(
                  context,
                  title: 'Populate Quick Add',
                  message:
                      'This will compute next unseen episodes for your TV shows and add them to Quick Add. Proceed?',
                  action: () async {
                    // Clear existing quick-add entries so the populate action
                    // fully reflects current seen history.
                    await provider.clearQuickAddItems();
                    await provider.populateQuickAddFromSeenHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quick Add populated from history.'),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Achievement Data'),
              ListTile(
                leading: Icon(Icons.stars_outlined, color: colors.error),
                title: Text(
                  'Clear Achievement Database',
                  style: TextStyle(color: colors.error),
                ),
                subtitle: const Text(
                  'Remove all persisted achievement milestones.',
                ),
                onTap: () => _confirmAction(
                  context,
                  title: 'Clear Achievements?',
                  message:
                      'This will remove all persisted achievement dates from the database. '
                      'Achievements calculated from your watch history will reappear automatically.',
                  action: () async {
                    await achievementProvider.clearAchievements();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Achievement database cleared.'),
                        ),
                      );
                    }
                  },
                ),
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
                          isImporting ? provider.importStatus : 'Processing...',
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
        dialogTitle: 'Save Export',
        fileName: fileName,
        initialDirectory: Platform.isAndroid ? _defaultPath : null,
        bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e. Try using "Share" instead.'),
          ),
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
      type: FileType.custom,
      allowedExtensions: ['zip'],
      initialDirectory: Platform.isAndroid ? _defaultPath : null,
    );

    if (!context.mounted) return;

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
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
            title: const Text('Import Preview'),
            content: Text(
              'This file contains:\n'
              'Seen: $seenCount\n'
              'Likes: $likesCount\n'
              'Notifications: $notCount\n'
              'Lists: $listsCount\n\n'
              'Choose how to apply the data to your current profile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await provider.importAllData(bytes, mode: ImportMode.append);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imported (Appended)')),
                    );
                  }
                },
                child: const Text('Append'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await provider.importAllData(bytes, mode: ImportMode.merge);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imported (Merged)')),
                    );
                  }
                },
                child: const Text('Merge'),
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
                        const SnackBar(content: Text('Imported (Replaced)')),
                      );
                    }
                  }
                },
                child: Text(
                  'Replace',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import failed: Invalid file format')),
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
            title: const Text('DANGER: Replace History'),
            content: const Text(
              'This will delete all your current seen history and replace it with the data from the file. This action cannot be undone. Are you absolutely sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Yes, Replace Everything',
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await action();
            },
            child: const Text('Proceed'),
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
