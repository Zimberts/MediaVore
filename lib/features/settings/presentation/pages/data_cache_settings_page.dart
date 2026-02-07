import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DataCacheSettingsPage extends StatelessWidget {
  const DataCacheSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  action: () async {
                    final data = await provider.exportSeenData();
                    await provider.importSeenData(
                      data,
                      mode: ImportMode.replace,
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Export Seen History'),
                subtitle: const Text('Export your viewing history as JSON.'),
                onTap: () => _showExportOptions(context, provider),
              ),
              ListTile(
                leading: const Icon(Icons.download_for_offline),
                title: const Text('Import Seen History'),
                subtitle: const Text(
                  'Import viewing history from a JSON file.',
                ),
                onTap: () => _importSeenData(context, provider),
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

  Future<void> _showExportOptions(
    BuildContext context,
    SearchProvider provider,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Export All History'),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportSeenData(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Filter by Date Range'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null && context.mounted) {
                  _exportSeenData(
                    context,
                    provider,
                    start: picked.start,
                    end: picked.end,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSeenData(
    BuildContext context,
    SearchProvider provider, {
    DateTime? start,
    DateTime? end,
  }) async {
    try {
      final data = await provider.exportSeenData(start: start, end: end);

      if (!context.mounted) return;

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No history found for the selected criteria.'),
          ),
        );
        return;
      }

      final jsonString = jsonEncode(data);

      final tempDir = await getTemporaryDirectory();
      String suffix = '';
      if (start != null && end != null) {
        suffix =
            '_${DateFormat('yyyyMMdd').format(start)}_to_${DateFormat('yyyyMMdd').format(end)}';
      }
      final fileName =
          'mediavore_seen_history${suffix}_${DateTime.now().millisecondsSinceEpoch}.json';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString);

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
                  subtitle: const Text(
                    'Choose location (defaults to Download)',
                  ),
                  onTap: () async {
                    Navigator.pop(saveSheetContext);
                    await _saveFileToDevice(context, jsonString, fileName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share via System'),
                  subtitle: const Text('Use the system share sheet'),
                  onTap: () async {
                    Navigator.pop(saveSheetContext);
                    await Share.shareXFiles([
                      XFile(tempFile.path, mimeType: 'application/json'),
                    ], text: 'My MediaVore Seen History');
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _saveFileToDevice(
    BuildContext context,
    String jsonString,
    String fileName,
  ) async {
    try {
      final bytes = utf8.encode(jsonString);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Seen History',
        fileName: fileName,
        initialDirectory: Platform.isAndroid ? _defaultPath : null,
        bytes: bytes,
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

  Future<void> _importSeenData(
    BuildContext context,
    SearchProvider provider,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      initialDirectory: Platform.isAndroid ? _defaultPath : null,
    );

    if (!context.mounted) return;

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (!context.mounted) return;
      final colors = context.appColors;

      try {
        final List<dynamic> data = jsonDecode(content);
        final List<Map<String, dynamic>> seenData = data
            .cast<Map<String, dynamic>>();

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Import Seen History'),
              content: Text(
                'You are about to import ${seenData.length} entries. Choose how to handle your current history:',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await provider.importSeenData(
                      seenData,
                      mode: ImportMode.append,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imported successfully (Appended)'),
                        ),
                      );
                    }
                  },
                  child: const Text('Append'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await provider.importSeenData(
                      seenData,
                      mode: ImportMode.merge,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imported successfully (Merged)'),
                        ),
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
                      await provider.importSeenData(
                        seenData,
                        mode: ImportMode.replace,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Imported successfully (Replaced)'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Replace', style: TextStyle(color: colors.error)),
                ),
              ],
            ),
          );
        }
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
