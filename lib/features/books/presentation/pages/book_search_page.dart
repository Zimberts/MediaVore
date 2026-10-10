import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/presentation/pages/book_detail_page.dart';
import 'package:mediavore/features/books/presentation/providers/book_provider.dart';
import 'package:provider/provider.dart';

class BookSearchPage extends StatefulWidget {
  const BookSearchPage({super.key});

  @override
  State<BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<BookSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Titre, auteur, ISBN...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: colors.comments),
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!),
          onSubmitted: (query) => _search(query),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          Consumer<BookProvider>(
            builder: (context, provider, _) {
              if (provider.searchQuery.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.searchQuery.isEmpty) {
            return _buildEmptyHint(colors);
          }

          if (provider.searchResults.isEmpty) {
            return _buildNoResults(colors);
          }

          return _buildResults(provider.searchResults, colors);
        },
      ),
    );
  }

  void _search(String query) {
    if (query.trim().isNotEmpty) {
      context.read<BookProvider>().searchBooks(query.trim());
    }
  }

  Widget _buildEmptyHint(AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: colors.comments),
          const SizedBox(height: 16),
          Text(
            'Recherchez un livre par titre, auteur ou ISBN',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: colors.comments),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Book> results, AppThemeExtension colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return _SearchResultCard(book: book);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Book book;
  const _SearchResultCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, s) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.menu_book, size: 24),
                          ),
                          errorWidget: (_, s, e) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.menu_book, size: 24),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.menu_book,
                            size: 24,
                            color: colors.comments,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorsDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (book.publishYear != null) ...[
                          Text(
                            '${book.publishYear}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.comments,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (book.pageCount != null)
                          Text(
                            '${book.pageCount} p.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.comments,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ISBN: ${book.isbn}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.comments,
                      ),
                    ),
                  ],
                ),
              ),
              // Add button
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: colors.logicFlow),
                onPressed: () async {
                  final provider = context.read<BookProvider>();
                  await provider.addBook(book);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${book.title} ajouté'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
