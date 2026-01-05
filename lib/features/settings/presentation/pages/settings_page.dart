import 'package:flutter/material.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final isCacheLoading = provider.isCacheLoading;
    final sizeInMb = (provider.cacheSize / (1024 * 1024)).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              const _SectionHeader(title: 'Cache Management'),
              ListTile(
                title: const Text('Cache Size'),
                subtitle: Text('$sizeInMb MB used'),
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
              const AboutListTile(
                icon: Icon(Icons.info_outline),
                applicationName: 'MediaVore',
                applicationVersion: '1.0.0',
                aboutBoxChildren: [
                  Text('A simple media tracking app using TMDB.'),
                ],
              ),
            ],
          ),
          if (isCacheLoading)
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
                        Text('Processing Cache...', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback action,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              action();
              Navigator.pop(context);
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
