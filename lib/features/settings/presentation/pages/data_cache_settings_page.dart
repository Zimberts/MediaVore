import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final isCacheLoading = provider.isCacheLoading;
    final isDbSizeLoading = provider.isDbSizeLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Data'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionHeader(title: 'Cache Management'),
              ListTile(
                title: const Text('Cache Size'),
                subtitle: Text(_formatBytes(provider.cacheSize)),
                trailing: isCacheLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.updateCacheSize(),
                    ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cleaning_services),
                title: const Text('Cleanup Cache'),
                subtitle: const Text('Remove old, unused search results and details.'),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: 'Cleanup Cache',
                  message: 'This will remove search results and details older than 60 days that are not in your lists.',
                  action: () => provider.clearCache(complete: false),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Fill Cache'),
                subtitle: const Text('Pre-cache all items in your lists and recent history for offline use.'),
                enabled: !isCacheLoading,
                onTap: () => provider.fillCache(),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Wipe All Cache', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Delete everything from cache.'),
                enabled: !isCacheLoading,
                onTap: () => _confirmAction(
                  context,
                  title: 'Wipe All Cache',
                  message: 'This will delete ALL cached posters and details. You will need internet to see them again.',
                  action: () => provider.clearCache(complete: true),
                ),
              ),
              const Divider(),
              const _SectionHeader(title: 'Data Management'),
              ListTile(
                title: const Text('Seen Database Size'),
                subtitle: Text(_formatBytes(provider.seenDbSize)),
                trailing: isDbSizeLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => provider.updateSeenDbSize(),
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
                subtitle: const Text('Import viewing history from a JSON file.'),
                onTap: () => _importSeenData(context, provider),
              ),
            ],
          ),
          if (isCacheLoading || isDbSizeLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _showExportOptions(BuildContext context, SearchProvider provider) async {
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
                  _exportSeenData(context, provider, start: picked.start, end: picked.end);
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
      
      if (data.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No history found for the selected criteria.')),
          );
        }
        return;
      }

      final jsonString = jsonEncode(data);
      
      final tempDir = await getTemporaryDirectory();
      String suffix = '';
      if (start != null && end != null) {
        suffix = '_${DateFormat('yyyyMMdd').format(start)}_to_${DateFormat('yyyyMMdd').format(end)}';
      }
      final fileName = 'mediavore_seen_history${suffix}_${DateTime.now().millisecondsSinceEpoch}.json';
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
                  subtitle: const Text('Choose location (defaults to Download)'),
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
                    await Share.shareXFiles(
                      [XFile(tempFile.path, mimeType: 'application/json')], 
                      text: 'My MediaVore Seen History'
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _saveFileToDevice(BuildContext context, String jsonString, String fileName) async {
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
          SnackBar(content: Text('Save failed: $e. Try using "Share" instead.')),
        );
      }
    }
  }

  Future<void> _importSeenData(BuildContext context, SearchProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      initialDirectory: Platform.isAndroid ? _defaultPath : null,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      
      try {
        final List<dynamic> data = jsonDecode(content);
        final List<Map<String, dynamic>> seenData = data.cast<Map<String, dynamic>>();

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Import Seen History'),
              content: Text('You are about to import ${seenData.length} entries. Choose how to handle your current history:'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await provider.importSeenData(seenData, mode: ImportMode.append);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Imported successfully (Appended)')),
                      );
                    }
                  },
                  child: const Text('Append'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await provider.importSeenData(seenData, mode: ImportMode.merge);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Imported successfully (Merged)')),
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
                      await provider.importSeenData(seenData, mode: ImportMode.replace);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Imported successfully (Replaced)')),
                        );
                      }
                    }
                  },
                  child: const Text('Replace', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: Invalid file format')),
          );
        }
      }
    }
  }

  Future<bool> _confirmReplace(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('DANGER: Replace History'),
        content: const Text('This will delete all your current seen history and replace it with the data from the file. This action cannot be undone. Are you absolutely sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, Replace Everything', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback action,
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
            onPressed: () {
              action();
              Navigator.pop(dialogContext); // Fixed: Pop dialogContext instead of context
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
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
