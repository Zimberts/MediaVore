import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/library/presentation/widgets/list_display_mode_sheet.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_grid_item.dart';
import 'package:mediavore/features/library/presentation/widgets/list_media_tile.dart';
import 'package:mediavore/features/library/presentation/widgets/list_share_sheet.dart';
import 'package:mediavore/features/library/presentation/widgets/list_sort_sheet.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:share_plus/share_plus.dart';

/// Page of a single list (design v1.5): sort, display mode (grid 2/3/4 or list),
/// selection, reordering, sharing and deletion.
class ListPage extends StatefulWidget {
  const ListPage({
    super.key,
    this.initialList = kWatchlistName,
    this.typeFilter,
    this.scrollController,
    this.onSearch,
  });

  /// The list to display. Defaults to the watchlist.
  final String initialList;

  /// Restricts the display to one media type (from the Library tab).
  final MediaType? typeFilter;

  /// Optional external scroll controller.
  final ScrollController? scrollController;

  /// Optional search callback (for legacy compatibility).
  final VoidCallback? onSearch;

  @override
  State<ListPage> createState() => ListPageState();
}

/// Backwards compatibility alias for [ListPage].
typedef SavedMediaPage = ListPage;

/// Backwards compatibility alias for [ListPageState].
typedef SavedMediaPageState = ListPageState;

class ListPageState extends State<ListPage> {
  static const double _gridPadding = 16.0;

  late String _selectedList;
  ListSortMethod _sortMethod = ListSortMethod.manual;
  bool _isReversed = false;
  int _shuffleSeed = 42;

  bool _isEditMode = false;
  final Set<String> _selectedItems = <String>{};

  List<MediaItem> _currentItems = [];
  String? _currentItemsList;
  Future<List<MediaItem>>? _savedMediaFuture;

  late final ScrollController _scrollController;
  final GlobalKey _qrKey = GlobalKey();
  double _gridDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _selectedList = widget.initialList;
    _scrollController = widget.scrollController ?? ScrollController();
    loadSavedMedia();
  }

  @override
  void didUpdateWidget(ListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialList != widget.initialList) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _selectedList = widget.initialList;
        _currentItems.clear();
        _currentItemsList = null;
        _sortMethod = ListSortMethod.manual;
        _isReversed = false;
        _isEditMode = false;
        _selectedItems.clear();
      });
      loadSavedMedia();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _pullToRefresh() async {
    await loadSavedMedia(forceRefresh: true);
    try {
      await _savedMediaFuture;
    } catch (_) {}
  }

  Future<void> loadSavedMedia({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (forceRefresh) {
      context.read<SearchProvider>().setOffline(false);
    }

    setState(() {
      _savedMediaFuture = _fetchSavedMedia();
    });
  }

  Future<List<MediaItem>> _fetchSavedMedia() async {
    final requestedList = _selectedList;
    final provider = context.read<SearchProvider>();
    final repository = provider.repository;

    final entries = await repository.getListEntries(requestedList);
    final localItems = await repository.getListPreviews(
      requestedList,
      limit: 1000,
    );

    List<MediaItem> items;
    if (provider.isOffline) {
      items = entries.map((entry) {
        final parts = entry.split(':');
        final id = int.parse(parts[0]);
        final typeStr = parts.length > 1 ? parts[1] : 'movie';
        final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;

        final local = localItems.firstWhere(
          (l) => l.id == id && l.type == type.name,
          orElse: () =>
              MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
        );

        return MediaItem(
          id: local.id,
          title: local.title,
          overview: '',
          releaseDate: '',
          mediaType: type,
          posterPath: local.posterPath,
        );
      }).toList();
    } else {
      final itemFutures = entries.map((entry) async {
        try {
          final parts = entry.split(':');
          final id = int.parse(parts[0]);
          final typeStr = parts.length > 1 ? parts[1] : 'movie';
          final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;

          try {
            final details = await provider.getMediaDetails(id, type);
            return details.item;
          } catch (_) {
            final local = localItems.firstWhere(
              (l) => l.id == id && l.type == typeStr,
              orElse: () =>
                  MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
            );
            return MediaItem(
              id: local.id,
              title: local.title,
              overview: '',
              releaseDate: '',
              mediaType: type,
              posterPath: local.posterPath,
            );
          }
        } catch (_) {
          return const MediaItem(
            id: 0,
            title: 'Error',
            overview: '',
            releaseDate: '',
          );
        }
      });
      items = (await Future.wait(
        itemFutures,
      )).where((item) => item.id != 0).toList();
    }

    if (mounted) {
      provider.loadAllSeenStatus();
    }

    if (requestedList == _selectedList) {
      _currentItems = items;
      _currentItemsList = requestedList;
    }
    return items;
  }

  List<MediaItem> _getFilteredAndSortedItems(
    List<MediaItem> items,
    SettingsProvider settings,
  ) {
    List<MediaItem> result = List.from(items);

    final typeFilter = widget.typeFilter;
    if (typeFilter != null) {
      result = result.where((item) => item.mediaType == typeFilter).toList();
    }

    if (settings.hideNonReleased) {
      final now = DateTime.now();
      result = result.where((item) {
        if (item.releaseDate.isEmpty) return false;
        final rel = DateTime.tryParse(item.releaseDate);
        return rel != null && rel.isBefore(now);
      }).toList();
    }

    switch (_sortMethod) {
      case ListSortMethod.releaseDate:
        result.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
        break;
      case ListSortMethod.shuffle:
        // Stable shuffle: uses fixed _shuffleSeed so rebuilding the widget does
        // not reshuffle the list.
        final random = Random(_shuffleSeed);
        result.shuffle(random);
        break;
      case ListSortMethod.manual:
        break;
    }

    if (_isReversed) {
      result = result.reversed.toList();
    }

    return result;
  }

  Future<void> _removeSelectedItems() async {
    final provider = context.read<SearchProvider>();
    final l10n = context.l10n;

    final selectedKeys = Set<String>.from(_selectedItems);
    final count = selectedKeys.length;
    if (count == 0) return;

    // Capture items with their positions in _currentItems to allow exact Undo
    final removedWithIndices = <(int, MediaItem)>[];
    for (var i = 0; i < _currentItems.length; i++) {
      final item = _currentItems[i];
      if (selectedKeys.contains('${item.id}:${item.mediaType.name}')) {
        removedWithIndices.add((i, item));
      }
    }

    setState(() {
      _currentItems.removeWhere(
        (item) => selectedKeys.contains('${item.id}:${item.mediaType.name}'),
      );
      _isEditMode = false;
      _selectedItems.clear();
    });

    for (final (_, item) in removedWithIndices) {
      await provider.removeFromList(item, _selectedList);
    }

    loadSavedMedia();

    // Unified action feedback with Undo (#302 / #312 amendment)
    showAppMessage(
      l10n.listsRemovedNotification(count),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        final restored = List<MediaItem>.from(_currentItems);
        for (final (index, item) in removedWithIndices) {
          final insertAt = index.clamp(0, restored.length);
          restored.insert(insertAt, item);
          await provider.toggleInList(item, _selectedList);
        }
        final ordered = restored
            .map((e) => '${e.id}:${e.mediaType.name}')
            .toList();
        await provider.updateListOrder(_selectedList, ordered);
        if (mounted) {
          loadSavedMedia();
        }
      },
    );
  }

  void _toggleSelectAll(List<MediaItem> visibleItems) {
    final visibleKeys = visibleItems
        .map((item) => '${item.id}:${item.mediaType.name}')
        .toSet();

    setState(() {
      if (_selectedItems.containsAll(visibleKeys)) {
        _selectedItems.removeAll(visibleKeys);
      } else {
        _selectedItems.addAll(visibleKeys);
      }
    });
  }

  void _toggleItemSelection(MediaItem item) {
    final key = '${item.id}:${item.mediaType.name}';
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
      } else {
        _selectedItems.add(key);
      }
    });
  }

  String _getOrderText(AppLocalizations l10n) {
    final base = switch (_sortMethod) {
      ListSortMethod.manual => l10n.listsSortOrderManual,
      ListSortMethod.releaseDate => l10n.listsSortOrderReleaseDate,
      ListSortMethod.shuffle => l10n.listsSortOrderShuffle,
    };
    return _isReversed ? l10n.listsSortOrderReversed(base) : base;
  }

  Future<void> _shareQRCodeImage() async {
    final l10n = context.l10n;
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/mediavore_qr_${_selectedList.replaceAll(' ', '_')}.png',
      ).create();
      await file.writeAsBytes(buffer);

      final message = l10n.listsQrShareMessage(_selectedList);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: message),
      );
    } catch (e) {
      if (mounted) {
        showAppMessage(l10n.listsQrShareError('$e'));
      }
    }
  }

  void _shareWebLink() {
    final provider = context.read<SearchProvider>();
    final link = provider.getShareLinkForList(_selectedList);
    SharePlus.instance.share(
      ShareParams(
        text: context.l10n.listsShareLinkMessage(_selectedList, link),
      ),
    );
  }

  Future<void> _showDeleteListConfirm() async {
    final l10n = context.l10n;
    final provider = context.read<SearchProvider>();

    final confirmed = await showAppDialog<bool>(
      context: context,
      title: l10n.listsDeleteList,
      message: l10n.listsDeleteListMessage(_selectedList),
      actions: [
        AppDialogAction(label: l10n.commonCancel, value: false),
        AppDialogAction(label: l10n.commonDelete, value: true, danger: true),
      ],
    );

    if (confirmed == true && mounted) {
      final toDelete = _selectedList;
      await provider.deleteList(toDelete);
      if (mounted) {
        Navigator.pop(context); // pop list page back to library
      }
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    int itemCount,
    List<MediaItem> visibleItems,
  ) {
    final l10n = context.l10n;
    final colors = context.appColors;

    if (_isEditMode) {
      final allSelected =
          visibleItems.isNotEmpty &&
          visibleItems.every(
            (item) =>
                _selectedItems.contains('${item.id}:${item.mediaType.name}'),
          );

      return AppBar(
        leading: AppTapTarget(
          tooltip: l10n.commonCancel,
          onTap: () {
            setState(() {
              _isEditMode = false;
              _selectedItems.clear();
            });
          },
          child: const Center(child: Icon(Icons.close)),
        ),
        title: Text(
          l10n.listsSelectedCount(_selectedItems.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          AppTapTarget(
            tooltip: allSelected ? l10n.listsDeselectAll : l10n.listsSelectAll,
            onTap: () => _toggleSelectAll(visibleItems),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  allSelected ? l10n.listsDeselectAll : l10n.listsSelectAll,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          AppTapTarget(
            tooltip: l10n.listsRemove,
            onTap: _selectedItems.isEmpty ? null : _removeSelectedItems,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: _selectedItems.isEmpty
                          ? colors.text2.withValues(alpha: 0.5)
                          : colors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.listsRemove,
                      style: TextStyle(
                        color: _selectedItems.isEmpty
                            ? colors.text2.withValues(alpha: 0.5)
                            : colors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final displayName = listDisplayName(l10n, _selectedList);
    final orderText = _getOrderText(l10n);
    final subtitle = l10n.listsHeaderSubtitle(itemCount, orderText);

    return AppBar(
      leading: AppTapTarget(
        tooltip: l10n.commonCancel,
        onTap: () => Navigator.maybePop(context),
        child: const Center(child: Icon(Icons.arrow_back)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: colors.text2,
            ),
          ),
        ],
      ),
      actions: [
        // Sort button (44 dp visible, 48 dp touch target)
        AppTapTarget(
          tooltip: l10n.listsSortOptions,
          onTap: () {
            showListSortSheet(
              context,
              currentMethod: _sortMethod,
              isReversed: _isReversed,
              onMethodChanged: (method) {
                setState(() {
                  _sortMethod = method;
                  if (method == ListSortMethod.shuffle) {
                    _shuffleSeed = DateTime.now().millisecondsSinceEpoch;
                  }
                });
              },
              onReversedChanged: (reversed) {
                setState(() => _isReversed = reversed);
              },
            );
          },
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(Icons.swap_vert)),
          ),
        ),
        // Display mode button (44 dp visible, 48 dp touch target)
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            final isList = settings.displayMode == DisplayMode.list;
            return AppTapTarget(
              tooltip: l10n.listsDisplayOptions,
              onTap: () {
                showListDisplayModeSheet(
                  context,
                  currentMode: settings.displayMode,
                  currentGridSize: settings.gridSize.round(),
                  onChanged: (mode, size) {
                    settings.setDisplayMode(mode);
                    settings.setGridSize(size.toDouble());
                  },
                );
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(isList ? Icons.view_list : Icons.grid_view),
                ),
              ),
            );
          },
        ),
        // More menu (44 dp visible, 48 dp touch target)
        PopupMenuButton<String>(
          key: const Key('lists_more_actions'),
          tooltip: l10n.listsMoreActions,
          icon: const SizedBox(
            width: 44,
            height: 44,
            child: Center(child: Icon(Icons.more_vert)),
          ),
          onSelected: (value) {
            switch (value) {
              case 'share':
                showListShareSheet(
                  context,
                  listName: displayName,
                  shareLink: context.read<SearchProvider>().getShareLinkForList(
                    _selectedList,
                  ),
                  qrKey: _qrKey,
                  onShareQrImage: _shareQRCodeImage,
                  onShareWebLink: _shareWebLink,
                );
                break;
              case 'select':
                setState(() {
                  _isEditMode = true;
                });
                break;
              case 'delete':
                _showDeleteListConfirm();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.listsActionShare),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'select',
              child: ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(l10n.listsActionSelect),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_selectedList != kWatchlistName)
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: colors.danger),
                  title: Text(
                    l10n.listsDeleteList,
                    style: TextStyle(color: colors.danger),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyState(
          icon: Icons.movie_outlined,
          title: l10n.listsEmpty,
          actionLabel: l10n.listsFillBySwiping,
          actionIcon: Icons.explore,
          onAction: () {
            context.read<SearchProvider>().setSelectedTab(AppTab.discover);
            Navigator.maybePop(context);
          },
        ),
      ),
    );
  }

  Widget _buildGridView(
    List<MediaItem> items,
    SearchProvider provider,
    SettingsProvider settings,
  ) {
    final columns = settings.gridSize.round().clamp(2, 4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridDelegate = MediaPosterCard.gridDelegate(
          context: context,
          width: constraints.maxWidth - 2 * _gridPadding,
          crossAxisCount: columns,
        );

        if (_sortMethod != ListSortMethod.manual || _isReversed) {
          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(_gridPadding),
            clipBehavior: Clip.none,
            gridDelegate: gridDelegate,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedItems.contains(
                '${item.id}:${item.mediaType.name}',
              );

              return ListMediaGridItem(
                key: ValueKey('${item.id}_${item.mediaType.name}'),
                item: item,
                provider: provider,
                isSelected: isSelected,
                isEditMode: _isEditMode,
                onTap: () async {
                  if (_isEditMode) {
                    _toggleItemSelection(item);
                  } else {
                    await MediaDetailPage.show(context, item);
                    loadSavedMedia();
                  }
                },
                onLongPress: _isEditMode
                    ? null
                    : () {
                        setState(() {
                          _isEditMode = true;
                          _selectedItems.add(
                            '${item.id}:${item.mediaType.name}',
                          );
                        });
                      },
              );
            },
          );
        }

        return ReorderableGridView.builder(
          padding: const EdgeInsets.all(_gridPadding),
          clipBehavior: Clip.none,
          dragEnabled: !_isEditMode,
          scrollSpeedController: (elapsed, overSize, itemSize) =>
              _gridDragDistance < 12 ? 0 : 5,
          gridDelegate: gridDelegate,
          itemCount: items.length,
          onDragStart: (_) => _gridDragDistance = 0,
          onDragUpdate: (_, _, delta) => _gridDragDistance += delta.distance,
          onReorder: (oldIndex, newIndex) async {
            if (_gridDragDistance < 12) {
              final pressed = items[oldIndex];
              setState(() {
                _isEditMode = true;
                _selectedItems.add('${pressed.id}:${pressed.mediaType.name}');
              });
              return;
            }

            setState(() {
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);

              final oldPersistentIndex = _currentItems.indexOf(item);
              if (oldPersistentIndex != -1) {
                _currentItems.removeAt(oldPersistentIndex);
              }

              if (newIndex < items.length - 1) {
                final nextItemInFiltered = items[newIndex + 1];
                final nextPersistentIndex = _currentItems.indexOf(
                  nextItemInFiltered,
                );
                if (nextPersistentIndex != -1) {
                  _currentItems.insert(nextPersistentIndex, item);
                } else {
                  _currentItems.add(item);
                }
              } else {
                if (items.length > 1 && newIndex > 0) {
                  final previousItemInFiltered = items[newIndex - 1];
                  final prevPersistentIndex = _currentItems.indexOf(
                    previousItemInFiltered,
                  );
                  if (prevPersistentIndex != -1) {
                    _currentItems.insert(prevPersistentIndex + 1, item);
                  } else {
                    _currentItems.add(item);
                  }
                } else {
                  _currentItems.add(item);
                }
              }
            });

            final orderedEntries = _currentItems
                .map((e) => '${e.id}:${e.mediaType.name}')
                .toList();
            await provider.updateListOrder(_selectedList, orderedEntries);
          },
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = _selectedItems.contains(
              '${item.id}:${item.mediaType.name}',
            );

            return ListMediaGridItem(
              key: ValueKey('${item.id}_${item.mediaType.name}'),
              item: item,
              provider: provider,
              isSelected: isSelected,
              isEditMode: _isEditMode,
              onTap: () async {
                if (_isEditMode) {
                  _toggleItemSelection(item);
                } else {
                  await MediaDetailPage.show(context, item);
                  loadSavedMedia();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<MediaItem> items, SearchProvider provider) {
    if (_sortMethod != ListSortMethod.manual || _isReversed || _isEditMode) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedItems.contains(
            '${item.id}:${item.mediaType.name}',
          );

          return ListMediaTile(
            key: ValueKey('${item.id}_${item.mediaType.name}'),
            index: index,
            item: item,
            provider: provider,
            isEditMode: _isEditMode,
            isSelected: isSelected,
            isManualSort: false,
            onTap: () async {
              if (_isEditMode) {
                _toggleItemSelection(item);
              } else {
                await MediaDetailPage.show(context, item);
                loadSavedMedia();
              }
            },
            onLongPress: () {
              if (!_isEditMode) {
                setState(() {
                  _isEditMode = true;
                  _selectedItems.add('${item.id}:${item.mediaType.name}');
                });
              }
            },
          );
        },
      );
    }

    return ReorderableListView.builder(
      scrollController: _scrollController,
      itemCount: items.length,
      clipBehavior: Clip.none,
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) async {
        setState(() {
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);

          final oldPersistentIndex = _currentItems.indexOf(item);
          if (oldPersistentIndex != -1) {
            _currentItems.removeAt(oldPersistentIndex);
          }

          if (newIndex < items.length - 1) {
            final nextItemInFiltered = items[newIndex + 1];
            final nextPersistentIndex = _currentItems.indexOf(
              nextItemInFiltered,
            );
            if (nextPersistentIndex != -1) {
              _currentItems.insert(nextPersistentIndex, item);
            } else {
              _currentItems.add(item);
            }
          } else {
            if (items.length > 1 && newIndex > 0) {
              final previousItemInFiltered = items[newIndex - 1];
              final prevPersistentIndex = _currentItems.indexOf(
                previousItemInFiltered,
              );
              if (prevPersistentIndex != -1) {
                _currentItems.insert(prevPersistentIndex + 1, item);
              } else {
                _currentItems.add(item);
              }
            } else {
              _currentItems.add(item);
            }
          }
        });

        final orderedEntries = _currentItems
            .map((e) => '${e.id}:${e.mediaType.name}')
            .toList();
        await provider.updateListOrder(_selectedList, orderedEntries);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItems.contains(
          '${item.id}:${item.mediaType.name}',
        );

        return ListMediaTile(
          key: ValueKey('${item.id}_${item.mediaType.name}'),
          index: index,
          item: item,
          provider: provider,
          isEditMode: _isEditMode,
          isSelected: isSelected,
          isManualSort: true,
          onTap: () async {
            if (_isEditMode) {
              _toggleItemSelection(item);
            } else {
              await MediaDetailPage.show(context, item);
              loadSavedMedia();
            }
          },
          onLongPress: () {
            if (!_isEditMode) {
              setState(() {
                _isEditMode = true;
                _selectedItems.add('${item.id}:${item.mediaType.name}');
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final settings = context.watch<SettingsProvider>();

    return FutureBuilder<List<MediaItem>>(
      future: _savedMediaFuture,
      builder: (context, snapshot) {
        final List<MediaItem> itemsToDisplay;
        if (_currentItemsList == _selectedList && _currentItems.isNotEmpty) {
          itemsToDisplay = _currentItems;
        } else if (snapshot.hasData) {
          itemsToDisplay = snapshot.data!;
        } else {
          itemsToDisplay = _currentItems;
        }

        final filteredItems = _getFilteredAndSortedItems(
          itemsToDisplay,
          settings,
        );

        return Scaffold(
          appBar: _buildAppBar(context, itemsToDisplay.length, filteredItems),
          body: RefreshIndicator(
            onRefresh: _pullToRefresh,
            child: filteredItems.isEmpty
                ? (snapshot.connectionState == ConnectionState.waiting &&
                          itemsToDisplay.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: _buildEmptyState(context),
                                ),
                              ),
                        ))
                : (settings.displayMode == DisplayMode.list
                      ? _buildListView(filteredItems, provider)
                      : _buildGridView(filteredItems, provider, settings)),
          ),
        );
      },
    );
  }
}
