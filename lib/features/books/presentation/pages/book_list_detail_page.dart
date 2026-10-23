import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/presentation/pages/book_detail_page.dart';
import 'package:mediavore/features/books/presentation/providers/book_provider.dart';
import 'package:provider/provider.dart';

class BookListDetailPage extends StatefulWidget {
  final String listName;

  const BookListDetailPage({super.key, required this.listName});

  @override
  State<BookListDetailPage> createState() => _BookListDetailPageState();
}

class _BookListDetailPageState extends State<BookListDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().loadListBooks(widget.listName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Renommer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer la liste'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = provider.currentListBooks;

          if (books.isEmpty) {
            return _buildEmptyState(colors);
          }

          return _buildBookList(books, colors, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.list_alt, size: 64, color: colors.comments),
          const SizedBox(height: 16),
          Text(
            'Cette liste est vide',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des livres depuis leur page de détail',
            style: TextStyle(fontSize: 14, color: colors.comments),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(
    List<Book> books,
    AppThemeExtension colors,
    BookProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Dismissible(
          key: Key(book.isbn),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.remove_circle, color: Colors.red),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Retirer de la liste'),
                content: Text(
                  'Retirer "${book.title}" de "${widget.listName}" ?\nLe livre restera dans votre bibliothèque.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Retirer'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            provider.removeBookFromList(book.isbn, widget.listName);
          },
          child: _BookListItem(book: book, colors: colors),
        );
      },
    );
  }

  void _handleMenuAction(String action) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer la liste'),
          content: Text(
            'Voulez-vous supprimer la liste "${widget.listName}" ?\nLes livres ne seront pas supprimés de votre bibliothèque.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        final provider = context.read<BookProvider>();
        await provider.deleteList(widget.listName);
        if (mounted) Navigator.pop(context);
      }
    }
  }
}

class _BookListItem extends StatelessWidget {
  final Book book;
  final AppThemeExtension colors;

  const _BookListItem({required this.book, required this.colors});

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 50,
                  height: 75,
                  child: book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, s) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.menu_book, size: 20),
                          ),
                          errorWidget: (_, s, e) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Icon(Icons.menu_book, size: 20),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.menu_book,
                            size: 20,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorsDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Read status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(book.readStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  book.readStatus.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor(book.readStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ReadStatus status) {
    switch (status) {
      case ReadStatus.read:
        return colors.success;
      case ReadStatus.reading:
        return colors.dataValues;
      case ReadStatus.unread:
        return colors.comments;
    }
  }
}
