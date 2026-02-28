import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/domain/repositories/book_repository.dart';
import 'package:mediavore/features/books/presentation/pages/book_detail_page.dart';
import 'package:mediavore/features/books/presentation/pages/book_list_detail_page.dart';
import 'package:mediavore/features/books/presentation/pages/book_scanner_page.dart';
import 'package:mediavore/features/books/presentation/pages/book_search_page.dart';
import 'package:mediavore/features/books/presentation/providers/book_provider.dart';
import 'package:provider/provider.dart';

class BookLibraryPage extends StatefulWidget {
  const BookLibraryPage({super.key});

  @override
  State<BookLibraryPage> createState() => _BookLibraryPageState();
}

class _BookLibraryPageState extends State<BookLibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scanner un code-barres',
            onPressed: () => _openScanner(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher un livre',
            onPressed: () => _openSearch(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes livres'),
            Tab(text: 'Mes listes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _BooksTab(),
          const _ListsTab(),
        ],
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookScannerPage()),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookSearchPage()),
    );
  }
}

// ── Books Tab ──

class _BooksTab extends StatelessWidget {
  const _BooksTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Stats row
            _StatsRow(provider: provider),
            // Filter chips
            _FilterChips(provider: provider),
            // Book grid
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.books.isEmpty
                      ? _EmptyState(
                          hasFilter: provider.filterStatus != null,
                          colors: colors,
                        )
                      : _BookGrid(books: provider.books),
            ),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final BookProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatChip(
            label: 'Total',
            count: provider.totalBookCount,
            color: colors.logicFlow,
          ),
          _StatChip(
            label: 'Lus',
            count: provider.readCount,
            color: colors.success,
          ),
          _StatChip(
            label: 'En cours',
            count: provider.readingCount,
            color: colors.dataValues,
          ),
          _StatChip(
            label: 'À lire',
            count: provider.unreadCount,
            color: colors.comments,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final BookProvider provider;
  const _FilterChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              context,
              label: 'Tous',
              selected: provider.filterStatus == null,
              color: colors.logicFlow,
              onTap: () => provider.setFilter(null),
            ),
            const SizedBox(width: 8),
            ...ReadStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildChip(
                    context,
                    label: status.label,
                    selected: provider.filterStatus == status,
                    color: _statusColor(status, colors),
                    onTap: () => provider.setFilter(status),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      onSelected: (_) => onTap(),
    );
  }

  Color _statusColor(ReadStatus status, AppThemeExtension colors) {
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

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final AppThemeExtension colors;
  const _EmptyState({required this.hasFilter, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.menu_book_outlined,
            size: 64,
            color: colors.comments,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? 'Aucun livre avec ce filtre'
                : 'Votre bibliothèque est vide',
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 8),
            Text(
              'Scannez un code-barres ou recherchez un livre',
              style: TextStyle(fontSize: 14, color: colors.comments),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final List<Book> books;
  const _BookGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _BookCard(book: books[index]),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, s) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Center(
                              child: Icon(Icons.menu_book, size: 32),
                            ),
                          ),
                          errorWidget: (_, s, e) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Center(
                              child: Icon(Icons.menu_book, size: 32),
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 32,
                              color: colors.comments,
                            ),
                          ),
                        ),
                  // Read status indicator
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor(book.readStatus, colors),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ReadStatus status, AppThemeExtension colors) {
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

// ── Lists Tab ──

class _ListsTab extends StatelessWidget {
  const _ListsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Consumer<BookProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Create list button
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: () => _showCreateListDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Créer une liste'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
            // Lists
            Expanded(
              child: provider.lists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.list_alt, size: 64, color: colors.comments),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune liste créée',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez des listes comme "À lire", "Favoris"...',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.comments,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: provider.lists.length,
                      itemBuilder: (context, index) {
                        final list = provider.lists[index];
                        return _BookListTile(list: list);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateListDialog(BuildContext context, BookProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle liste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ex: Livres à lire, Science-fiction...',
            labelText: 'Nom de la liste',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                provider.createList(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final BookList list;
  const _BookListTile({required this.list});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.logicFlow.withValues(alpha: 0.15),
          child: Icon(Icons.list, color: colors.logicFlow),
        ),
        title: Text(list.name),
        subtitle: Text(
          '${list.itemCount} livre${list.itemCount != 1 ? 's' : ''}',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookListDetailPage(listName: list.name),
            ),
          );
        },
        onLongPress: () => _showDeleteDialog(context, list.name),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String listName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la liste'),
        content: Text(
          'Voulez-vous supprimer la liste "$listName" ?\nLes livres ne seront pas supprimés de votre bibliothèque.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<BookProvider>().deleteList(listName);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
