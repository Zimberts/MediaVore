import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_intersection_calculator.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Page displaying the intersection between an incoming shared list and one of the user's lists.
class ListIntersectionPage extends StatefulWidget {
  final ListSharePayload sharedPayload;

  const ListIntersectionPage({super.key, required this.sharedPayload});

  @override
  State<ListIntersectionPage> createState() => _ListIntersectionPageState();
}

class _ListIntersectionPageState extends State<ListIntersectionPage> {
  String? _selectedMyList;
  bool _hideSeen = false;
  bool _isLoading = false;
  final Map<String, MediaItem> _mediaCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaultList();
    });
  }

  void _initDefaultList() {
    final provider = context.read<SearchProvider>();
    final names = provider.listNames;
    if (names.isNotEmpty) {
      setState(() {
        _selectedMyList = names.contains('watchlist')
            ? 'watchlist'
            : names.first;
      });
      _fetchMediaDetails();
    }
  }

  Future<void> _fetchMediaDetails() async {
    final provider = context.read<SearchProvider>();
    final entries = widget.sharedPayload.entries;
    if (entries.isEmpty) return;

    setState(() => _isLoading = true);
    for (final entry in entries) {
      final key = '${entry.id}:${entry.type.name}';
      if (_mediaCache.containsKey(key)) continue;

      try {
        final details = await provider.getMediaDetails(entry.id, entry.type);
        _mediaCache[key] = details.item;
      } catch (_) {
        _mediaCache[key] = MediaItem(
          id: entry.id,
          title: 'Unknown',
          overview: '',
          releaseDate: '',
          mediaType: entry.type,
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);
    final myLists = provider.listNames;

    final myListEntries = _selectedMyList != null
        ? ListShareCodec.parseEntries(
            provider.listEntries[_selectedMyList!] ?? const [],
          )
        : <SharedMediaEntry>[];

    final seenKeys = {for (final s in provider.seenItems) (s.tmdbId, s.type)};

    final intersection = ListIntersectionCalculator.intersect(
      listA: widget.sharedPayload.entries,
      listB: myListEntries,
      seenKeys: seenKeys,
    );

    final visibleEntries = _hideSeen
        ? intersection.unseenCommonEntries
        : intersection.commonEntries;

    final otherListName = widget.sharedPayload.name.isNotEmpty
        ? widget.sharedPayload.name
        : context.l10n.listsSharingImporting;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.listsCompareTitle),
        actions: [
          if (visibleEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: context.l10n.listsCompareShareIntersection,
              onPressed: () =>
                  _shareIntersection(visibleEntries, otherListName),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildComparisonHeader(
            context,
            theme,
            myLists,
            otherListName,
            intersection,
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleEntries.isEmpty
                ? _buildEmptyState(context, otherListName)
                : _buildEntriesList(visibleEntries, seenKeys),
          ),
        ],
      ),
      bottomNavigationBar: visibleEntries.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  key: const Key('save_intersection_as_list_button'),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(
                    context.l10n.listsCompareSaveAsList(visibleEntries.length),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _saveAsList(visibleEntries, otherListName),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildComparisonHeader(
    BuildContext context,
    ThemeData theme,
    List<String> myLists,
    String otherListName,
    ListIntersectionResult intersection,
  ) {
    final colors = context.appColors;
    final primary = theme.colorScheme.primary;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: colors.text2,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        otherListName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '∩',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ),
              Expanded(
                child: myLists.isEmpty
                    ? Text(context.l10n.listsEmpty)
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('compare_my_list_dropdown'),
                          value: myLists.contains(_selectedMyList)
                              ? _selectedMyList
                              : myLists.first,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items: myLists.map((name) {
                            final label = name == 'watchlist'
                                ? context.l10n.listsWatchlist
                                : name;
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null && newVal != _selectedMyList) {
                              setState(() => _selectedMyList = newVal);
                            }
                          },
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.l10n.listsCompareCommonCount(intersection.totalCount),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (intersection.seenCount > 0)
                FilterChip(
                  key: const Key('hide_seen_toggle_chip'),
                  selected: _hideSeen,
                  label: Text(
                    '${context.l10n.listsCompareHideSeen} (${intersection.seenCount})',
                  ),
                  onSelected: (val) {
                    setState(() => _hideSeen = val);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String otherListName) {
    final myListName = _selectedMyList == 'watchlist'
        ? context.l10n.listsWatchlist
        : (_selectedMyList ?? '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyState(
          icon: Icons.filter_list_off,
          title: context.l10n.listsCompareEmptyTitle,
          message: context.l10n.listsCompareEmptyMessage(
            otherListName,
            myListName,
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList(
    List<SharedMediaEntry> entries,
    Set<(int id, MediaType type)> seenKeys,
  ) {
    final colors = context.appColors;

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final key = '${entry.id}:${entry.type.name}';
        final item =
            _mediaCache[key] ??
            MediaItem(
              id: entry.id,
              title: '...',
              overview: '',
              releaseDate: '',
              mediaType: entry.type,
            );

        final isSeen = seenKeys.contains((entry.id, entry.type));

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 44,
                height: 64,
                child: item.posterPath != null && item.posterPath!.isNotEmpty
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w185${item.posterPath}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.movie, color: colors.placeholder),
                      )
                    : Icon(
                        entry.type == MediaType.tv ? Icons.tv : Icons.movie,
                        color: colors.placeholder,
                      ),
              ),
            ),
            title: Text(
              item.title.isNotEmpty ? item.title : 'ID: ${item.id}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.placeholder.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.type == MediaType.tv
                        ? context.l10n.mediaTypeTv
                        : context.l10n.mediaTypeMovie,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (item.releaseDate.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    DateTime.tryParse(item.releaseDate)?.year.toString() ?? '',
                    style: TextStyle(color: colors.text2, fontSize: 12),
                  ),
                ],
                if (isSeen) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 14, color: colors.success),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              MediaDetailPage.show(context, item);
            },
          ),
        );
      },
    );
  }

  void _shareIntersection(
    List<SharedMediaEntry> entries,
    String otherListName,
  ) {
    final title = context.l10n.listsCompareDefaultIntersectionName(
      otherListName,
    );
    final link = ListShareCodec.createShareUrl(
      listName: title,
      entries: entries,
      version: 2,
    );
    Share.share(link, subject: title);
  }

  Future<void> _saveAsList(
    List<SharedMediaEntry> entries,
    String otherListName,
  ) async {
    final defaultName = context.l10n.listsCompareDefaultIntersectionName(
      otherListName,
    );
    final controller = TextEditingController(text: defaultName);

    final confirmedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.listsCreateNew),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: dialogContext.l10n.listsNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(dialogContext.l10n.commonSave),
          ),
        ],
      ),
    );

    if (confirmedName != null && confirmedName.isNotEmpty && mounted) {
      final provider = context.read<SearchProvider>();
      await provider.importSharedEntries(confirmedName, entries);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.listsCompareSaveAsListSuccess)),
        );
      }
    }
  }
}
