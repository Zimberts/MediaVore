import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/presentation/providers/book_provider.dart';
import 'package:provider/provider.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late Book _book;
  bool _isInLibrary = false;
  List<String> _bookLists = [];

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _checkLibraryStatus();
  }

  Future<void> _checkLibraryStatus() async {
    final provider = context.read<BookProvider>();
    final existing = await provider.getBookByIsbn(_book.isbn);
    final lists = await provider.getListsForBook(_book.isbn);
    if (mounted) {
      setState(() {
        _isInLibrary = existing != null;
        if (existing != null) _book = existing;
        _bookLists = lists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          SliverToBoxAdapter(child: _buildContent(colors)),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppThemeExtension colors) {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background cover
            if (_book.coverUrl != null)
              CachedNetworkImage(
                imageUrl: _book.coverUrl!,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withValues(alpha: 0.5),
                placeholder: (_, s) => Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
                errorWidget: (_, s, e) => Container(
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
            else
              Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            // Centered cover image with shadow
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Container(
                  height: 240,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _book.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, s) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, s, e) => Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: const Center(
                                child: Icon(Icons.menu_book, size: 48),
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Icon(
                                Icons.menu_book,
                                size: 48,
                                color: colors.comments,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_isInLibrary)
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildContent(AppThemeExtension colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _book.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Authors
          Text(
            _book.authorsDisplay,
            style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 16),

          // Read status & Add to library
          if (_isInLibrary) ...[
            _buildReadStatusSelector(colors),
            const SizedBox(height: 16),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToLibrary,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter à la bibliothèque'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Quick info
          _buildInfoRow(colors),
          const SizedBox(height: 16),

          // Lists
          if (_isInLibrary) ...[
            _buildListsSection(colors),
            const SizedBox(height: 16),
          ],

          // Description
          if (_book.description != null && _book.description!.isNotEmpty) ...[
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _book.description!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReadStatusSelector(AppThemeExtension colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut de lecture',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ReadStatus.values.map((status) {
                final isSelected = _book.readStatus == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        status.label,
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      selectedColor:
                          _statusColor(status, colors).withValues(alpha: 0.2),
                      checkmarkColor: _statusColor(status, colors),
                      onSelected: (_) => _updateReadStatus(status),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeExtension colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (_book.publisher != null)
          _InfoChip(
            icon: Icons.business,
            label: _book.publisher!,
            colors: colors,
          ),
        if (_book.publishYear != null)
          _InfoChip(
            icon: Icons.calendar_today,
            label: '${_book.publishYear}',
            colors: colors,
          ),
        if (_book.pageCount != null)
          _InfoChip(
            icon: Icons.auto_stories,
            label: '${_book.pageCount} pages',
            colors: colors,
          ),
        _InfoChip(
          icon: Icons.qr_code,
          label: 'ISBN: ${_book.isbn}',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildListsSection(AppThemeExtension colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Listes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: colors.logicFlow),
                  onPressed: () => _showAddToListDialog(),
                  iconSize: 20,
                ),
              ],
            ),
            if (_bookLists.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ce livre n\'est dans aucune liste',
                  style: TextStyle(fontSize: 13, color: colors.comments),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _bookLists
                    .map((name) => Chip(
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          deleteIcon:
                              const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeFromList(name),
                          backgroundColor:
                              colors.logicFlow.withValues(alpha: 0.1),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddToListDialog() async {
    final provider = context.read<BookProvider>();
    final allLists = provider.lists;

    if (!mounted) return;

    final selectedList = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ajouter à une liste'),
        children: [
          ...allLists
              .where((l) => !_bookLists.contains(l.name))
              .map((list) => SimpleDialogOption(
                    child: Text(list.name),
                    onPressed: () => Navigator.pop(ctx, list.name),
                  )),
          const Divider(),
          SimpleDialogOption(
            child: Row(
              children: [
                Icon(Icons.add, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Créer une nouvelle liste'),
              ],
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showCreateListDialog();
            },
          ),
        ],
      ),
    );

    if (selectedList != null && mounted) {
      await provider.addBookToList(_book.isbn, selectedList);
      _checkLibraryStatus();
    }
  }

  void _showCreateListDialog() {
    final controller = TextEditingController();
    final provider = context.read<BookProvider>();

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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await provider.createList(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  await provider.addBookToList(_book.isbn, name);
                  _checkLibraryStatus();
                }
              }
            },
            child: const Text('Créer et ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromList(String listName) async {
    final provider = context.read<BookProvider>();
    await provider.removeBookFromList(_book.isbn, listName);
    _checkLibraryStatus();
  }

  Future<void> _addToLibrary() async {
    final provider = context.read<BookProvider>();
    await provider.addBook(_book);
    _checkLibraryStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_book.title} ajouté à la bibliothèque'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateReadStatus(ReadStatus status) async {
    final provider = context.read<BookProvider>();
    await provider.updateReadStatus(_book.isbn, status);
    setState(() {
      _book = _book.copyWith(readStatus: status);
    });
  }

  void _handleMenuAction(String action) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Supprimer le livre'),
          content: Text(
            'Voulez-vous supprimer "${_book.title}" de votre bibliothèque ?',
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
        await provider.deleteBook(_book.isbn);
        if (mounted) Navigator.pop(context);
      }
    }
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppThemeExtension colors;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.comments),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
