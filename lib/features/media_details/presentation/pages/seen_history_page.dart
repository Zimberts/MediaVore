import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/history_grouping.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/core/widgets/scrollable_fill.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

enum SeenSort { dateDesc, dateAsc, nameAsc, nameDesc }

enum SeenViewMode { history, library }

class SeenHistoryPage extends StatefulWidget {
  const SeenHistoryPage({
    super.key,
    this.typeFilter,
    this.externalTypeFilter = false,
  });

  /// Media type imposed by the host (the Library tab); `null` shows all.
  /// Only read when [externalTypeFilter] is set.
  final MediaType? typeFilter;

  /// The host owns the type filter: the page follows [typeFilter] and hides
  /// its own type selector.
  final bool externalTypeFilter;

  @override
  State<SeenHistoryPage> createState() => SeenHistoryPageState();
}

class SeenHistoryPageState extends State<SeenHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SeenSort _currentSort = SeenSort.dateDesc;
  SeenViewMode _viewMode = SeenViewMode.history;
  MediaType? _ownFilterType;

  MediaType? get _filterType =>
      widget.externalTypeFilter ? widget.typeFilter : _ownFilterType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  List<SeenItem> _filterAndSortHistory(List<SeenItem> items) {
    final filtered = items.where((item) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery);
      final matchesType = _filterType == null || item.type == _filterType;
      return matchesQuery && matchesType;
    }).toList();

    switch (_currentSort) {
      case SeenSort.dateDesc:
        filtered.sort((a, b) => b.seenDate.compareTo(a.seenDate));
        break;
      case SeenSort.dateAsc:
        filtered.sort((a, b) => a.seenDate.compareTo(b.seenDate));
        break;
      case SeenSort.nameAsc:
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SeenSort.nameDesc:
        filtered.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
    }
    return filtered;
  }

  List<HistoryLibraryEntry> _filterAndSortLibrary(List<SeenItem> items) {
    final aggregated = aggregateHistoryLibraryEntries(items);
    final filtered = aggregated.where((entry) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          entry.latestItem.title.toLowerCase().contains(_searchQuery);
      final matchesType =
          _filterType == null || entry.latestItem.type == _filterType;
      return matchesQuery && matchesType;
    }).toList();

    switch (_currentSort) {
      case SeenSort.dateDesc:
        filtered.sort(
          (a, b) => b.latestItem.seenDate.compareTo(a.latestItem.seenDate),
        );
        break;
      case SeenSort.dateAsc:
        filtered.sort(
          (a, b) => a.latestItem.seenDate.compareTo(b.latestItem.seenDate),
        );
        break;
      case SeenSort.nameAsc:
        filtered.sort(
          (a, b) => a.latestItem.title.toLowerCase().compareTo(
            b.latestItem.title.toLowerCase(),
          ),
        );
        break;
      case SeenSort.nameDesc:
        filtered.sort(
          (a, b) => b.latestItem.title.toLowerCase().compareTo(
            a.latestItem.title.toLowerCase(),
          ),
        );
        break;
    }
    return filtered;
  }

  Future<void> _confirmAndDelete(BuildContext context, SeenItem item) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: l10n.seenRemoveLogTitle,
      message: l10n.seenRemoveLogMessage,
      actions: [
        AppDialogAction(label: l10n.commonCancel, value: false),
        AppDialogAction(label: l10n.commonRemove, value: true, danger: true),
      ],
    );

    if (confirmed == true && item.id != null && context.mounted) {
      await context.read<SearchProvider>().deleteSeenEntry(item.id!);
    }
  }

  Widget _buildLeading(SeenItem item, AppThemeExtension colors) {
    final isTv = item.type == MediaType.tv;
    final hasPoster = item.posterPath != null && item.posterPath!.isNotEmpty;

    if (hasPoster && !Platform.environment.containsKey('FLUTTER_TEST')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
          width: 44,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 44,
            height: 64,
            color: colors.surface2,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 44,
            height: 64,
            color: colors.surface2,
            child: Center(
              child: Icon(isTv ? Icons.tv : Icons.movie, color: colors.text2),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          isTv ? Icons.tv : Icons.movie,
          color: colors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildHistoryItemRow(
    BuildContext context,
    SeenItem item,
    SearchProvider provider,
    AppThemeExtension colors,
  ) {
    final l10n = context.l10n;
    final isLiked = provider.likedIds.contains(
      '${item.tmdbId}:${item.type.name}',
    );
    final isTv = item.type == MediaType.tv;

    // Subtitle formatting
    String subtitle = '';
    if (isTv && item.seasonNumber != null && item.episodeNumber != null) {
      subtitle = l10n.historyEpisodeSubtitle(
        item.seasonNumber!,
        item.episodeNumber!,
      );
      if (item.runtime != null && item.runtime! > 0) {
        subtitle += ' · ${formatHistoryDuration(item.runtime)}';
      }
    } else if (item.runtime != null && item.runtime! > 0) {
      subtitle = formatHistoryDuration(item.runtime);
    }

    if (_currentSort == SeenSort.nameAsc || _currentSort == SeenSort.nameDesc) {
      final dateStr = DateFormat.yMd().format(item.seenDate);
      subtitle = subtitle.isNotEmpty ? '$subtitle · $dateStr' : dateStr;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(item, colors),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isLiked)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Icon(Icons.favorite, size: 16, color: colors.likeHeart),
            ),
        ],
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(color: colors.text2, fontSize: 13))
          : null,
      trailing: PopupMenuButton<String>(
        key: Key('history_item_menu_${item.id}'),
        tooltip: l10n.listsMoreActions,
        icon: const SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(Icons.more_vert)),
        ),
        onSelected: (action) {
          if (action == 'open') {
            MediaDetailPage.show(
              context,
              MediaItem(
                id: item.tmdbId,
                title: item.title,
                overview: '',
                releaseDate: '',
                mediaType: item.type,
                posterPath: item.posterPath,
              ),
            );
          } else if (action == 'delete') {
            _confirmAndDelete(context, item);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.historyActionOpenDetail),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: colors.danger),
              title: Text(
                l10n.historyActionDeleteViewing,
                style: TextStyle(color: colors.danger),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () {
        MediaDetailPage.show(
          context,
          MediaItem(
            id: item.tmdbId,
            title: item.title,
            overview: '',
            releaseDate: '',
            mediaType: item.type,
            posterPath: item.posterPath,
          ),
        );
      },
    );
  }

  Widget _buildLibraryItemRow(
    BuildContext context,
    HistoryLibraryEntry entry,
    SearchProvider provider,
    AppThemeExtension colors,
  ) {
    final l10n = context.l10n;
    final item = entry.latestItem;
    final isLiked = provider.likedIds.contains(
      '${item.tmdbId}:${item.type.name}',
    );
    final isTv = item.type == MediaType.tv;

    String subtitle = '';
    if (isTv) {
      subtitle = l10n.historyTvLibrarySubtitle(
        entry.uniqueEpisodesCount,
        entry.totalEntries,
      );
    } else {
      subtitle = l10n.historyTimesSeen(entry.totalEntries);
    }

    if (_currentSort == SeenSort.nameAsc || _currentSort == SeenSort.nameDesc) {
      final dateStr = DateFormat.yMd().format(item.seenDate);
      subtitle += ' · $dateStr';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(item, colors),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (isLiked)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Icon(Icons.favorite, size: 16, color: colors.likeHeart),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.text2, fontSize: 13),
      ),
      trailing: PopupMenuButton<String>(
        key: Key('history_item_menu_${item.id}'),
        tooltip: l10n.listsMoreActions,
        icon: const SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Icon(Icons.more_vert)),
        ),
        onSelected: (action) {
          if (action == 'open') {
            MediaDetailPage.show(
              context,
              MediaItem(
                id: item.tmdbId,
                title: item.title,
                overview: '',
                releaseDate: '',
                mediaType: item.type,
                posterPath: item.posterPath,
              ),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.historyActionOpenDetail),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () {
        MediaDetailPage.show(
          context,
          MediaItem(
            id: item.tmdbId,
            title: item.title,
            overview: '',
            releaseDate: '',
            mediaType: item.type,
            posterPath: item.posterPath,
          ),
        );
      },
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    HistoryDayGroup group,
    AppThemeExtension colors,
  ) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final dayTitle = formatHistoryDayTitle(
      group.date,
      DateTime.now(),
      locale: locale,
      todayLabel: l10n.historyToday,
      yesterdayLabel: l10n.historyYesterday,
    );

    final countStr = l10n.historyDayHeaderSubtitle(group.itemCount);
    final durationStr = group.hasAnyKnownRuntime
        ? ' · ${formatHistoryDuration(group.totalRuntimeMinutes)}'
        : '';
    final fullHeader = '$dayTitle · $countStr$durationStr';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: colors.surface2.withValues(alpha: 0.5),
      child: Text(
        fullHeader,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildHeaderControls(
    BuildContext context,
    AppThemeExtension colors,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.seenSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Segment: Historique | Bibliothèque + Sort button
          Row(
            children: [
              Expanded(
                child: AppSegmented<SeenViewMode>(
                  segments: [
                    AppSegment(
                      value: SeenViewMode.history,
                      label: l10n.historySegmentHistory,
                    ),
                    AppSegment(
                      value: SeenViewMode.library,
                      label: l10n.historySegmentLibrary,
                    ),
                  ],
                  selected: _viewMode,
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
              ),
              const SizedBox(width: 8),
              // Sort menu button (44 dp visible, 48 dp touch target)
              PopupMenuButton<SeenSort>(
                key: const Key('history_sort_button'),
                tooltip: l10n.seenSortBy,
                icon: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: Icon(Icons.swap_vert)),
                ),
                onSelected: (sort) => setState(() => _currentSort = sort),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SeenSort.dateDesc,
                    child: ListTile(
                      title: Text(l10n.historySortRecent),
                      trailing: _currentSort == SeenSort.dateDesc
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: SeenSort.dateAsc,
                    child: ListTile(
                      title: Text(l10n.historySortOldest),
                      trailing: _currentSort == SeenSort.dateAsc
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: SeenSort.nameAsc,
                    child: ListTile(
                      title: Text(l10n.historySortTitleAsc),
                      trailing: _currentSort == SeenSort.nameAsc
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: SeenSort.nameDesc,
                    child: ListTile(
                      title: Text(l10n.historySortTitleDesc),
                      trailing: _currentSort == SeenSort.nameDesc
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Mode reminder line
          Text(
            _viewMode == SeenViewMode.history
                ? l10n.historyModeChronologicalHint
                : l10n.historyModeLibraryHint,
            style: TextStyle(
              color: colors.text2,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final allSeenItems = provider.seenItems;
    final l10n = context.l10n;
    final colors = context.appColors;

    final isHistoryMode = _viewMode == SeenViewMode.history;
    final isDateSort =
        _currentSort == SeenSort.dateDesc || _currentSort == SeenSort.dateAsc;

    final historyFiltered = isHistoryMode
        ? _filterAndSortHistory(allSeenItems)
        : null;
    final libraryFiltered = !isHistoryMode
        ? _filterAndSortLibrary(allSeenItems)
        : null;
    final hasNoMatches = isHistoryMode
        ? historyFiltered!.isEmpty
        : libraryFiltered!.isEmpty;

    final List<HistoryDayGroup> dayGroups =
        (isHistoryMode && isDateSort && historyFiltered != null)
        ? groupSeenItemsByDay(historyFiltered)
        : const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.seenTitle)),
      body: RefreshIndicator(
        onRefresh: provider.loadAllSeenStatus,
        child: Column(
          children: [
            _buildHeaderControls(context, colors, l10n),
            Expanded(
              child: allSeenItems.isEmpty
                  ? ScrollableFill(
                      child: EmptyState(
                        icon: Icons.history,
                        title: l10n.seenEmpty,
                        message: l10n.seenEmptyHint,
                        actionLabel: l10n.emptyStateSearchAction,
                        actionIcon: Icons.search,
                        onAction: () => context
                            .read<SearchProvider>()
                            .setSelectedTab(AppTab.discover),
                      ),
                    )
                  : hasNoMatches
                  ? ScrollableFill(
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: l10n.seenNoMatches,
                      ),
                    )
                  : isHistoryMode
                  ? (isDateSort
                        ? ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: dayGroups.length,
                            itemBuilder: (context, groupIndex) {
                              final group = dayGroups[groupIndex];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildDayHeader(context, group, colors),
                                  for (final item in group.items)
                                    _buildHistoryItemRow(
                                      context,
                                      item,
                                      provider,
                                      colors,
                                    ),
                                ],
                              );
                            },
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: historyFiltered!.length,
                            itemBuilder: (context, index) {
                              final item = historyFiltered[index];
                              return _buildHistoryItemRow(
                                context,
                                item,
                                provider,
                                colors,
                              );
                            },
                          ))
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: libraryFiltered!.length,
                      itemBuilder: (context, index) {
                        final entry = libraryFiltered[index];
                        return _buildLibraryItemRow(
                          context,
                          entry,
                          provider,
                          colors,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
