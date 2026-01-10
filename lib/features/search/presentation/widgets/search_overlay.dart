import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'dart:async';

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<SearchProvider>();
      provider.searchMedia(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search movies, TV shows...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              context.read<SearchProvider>().clearSearch();
            },
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = provider.items;
          if (items.isEmpty && _controller.text.isNotEmpty) {
            return const Center(child: Text('No results found'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.posterPath != null
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w92${item.posterPath}',
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.movie),
                      )
                    : const Icon(Icons.movie),
                title: Text(item.title),
                subtitle: Text(item.releaseDate),
                onTap: () {
                  MediaDetailPage.show(context, item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
