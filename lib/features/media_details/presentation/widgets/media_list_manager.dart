import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class MediaListManager extends StatelessWidget {
  final int itemId;
  final MediaType mediaType;
  final String title;

  const MediaListManager({
    super.key,
    required this.itemId,
    required this.mediaType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final item = MediaItem(
          id: itemId,
          title: title,
          overview: '',
          posterPath: null,
          releaseDate: '',
          mediaType: mediaType,
        );

        final isInWatchlist = provider.isItemInList(item, 'watchlist');

        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => provider.toggleInList(item, 'watchlist'),
              icon: Icon(isInWatchlist ? Icons.check : Icons.add),
              label: Text(isInWatchlist ? 'On Watchlist' : 'Add to Watchlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isInWatchlist ? Colors.green : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddToListDialog(context, provider, item),
              icon: const Icon(Icons.list),
              label: const Text('Add to list...'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddToListDialog(BuildContext context, SearchProvider provider, MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final otherLists = provider.listNames.where((name) => name != 'watchlist').toList();
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manage Lists', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (otherLists.isEmpty)
                    const Text('No custom lists yet.')
                  else
                    ...otherLists.map((listName) {
                      final isInThisList = provider.isItemInList(item, listName);
                      return CheckboxListTile(
                        title: Text(listName),
                        value: isInThisList,
                        onChanged: (value) async {
                          await provider.toggleInList(item, listName);
                          setModalState(() {});
                        },
                      );
                    }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create new list'),
                    onTap: () => _showCreateListDialog(context, provider),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateListDialog(BuildContext context, SearchProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'List name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.createList(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
