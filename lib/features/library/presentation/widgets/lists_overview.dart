import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/features/library/presentation/widgets/list_dialogs.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Name under which the default list is stored; shown translated.
const String kWatchlistName = 'watchlist';

/// Number of mini posters on a list row.
const int kListRowPreviewCount = 3;

/// Displayed name of the list stored as [name].
String listDisplayName(AppLocalizations l10n, String name) =>
    name == kWatchlistName ? l10n.listsWatchlist : name;

/// Overview of every list: one row per list (mini posters, name, films /
/// series split, count), then "New list" and "Import".
///
/// [type] restricts the counts and the mini posters to one media type.
class ListsOverview extends StatefulWidget {
  const ListsOverview({
    super.key,
    required this.onOpenList,
    this.type,
    this.scannerBuilder,
  });

  /// `null` shows every type.
  final MediaType? type;

  final ValueChanged<String> onOpenList;

  /// Replaces the camera of the QR import (tests).
  final ListScannerBuilder? scannerBuilder;

  @override
  State<ListsOverview> createState() => _ListsOverviewState();
}

class _ListsOverviewState extends State<ListsOverview> {
  /// Mini posters fetched for a type filter, by request signature. The
  /// provider only caches the first few previews of each list, which may not
  /// hold enough titles of the filtered type.
  final Map<String, List<MediaItemPreview>> _typedPreviews = {};
  final Set<String> _requested = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lib = context.read<LibraryProvider?>();
      if (lib != null) {
        lib.loadLists();
      } else {
        context.read<SearchProvider>().loadLists();
      }
    });
  }

  List<MediaItemPreview> _previews(dynamic provider, String name) {
    final cached = provider.getPreviewsForList(name);
    final type = widget.type;
    if (type == null) return cached.take(kListRowPreviewCount).toList();

    final entries = provider.getListEntriesOfType(name, type);
    final wanted = entries.length < kListRowPreviewCount
        ? entries.length
        : kListRowPreviewCount;
    final fromCache = cached
        .where((preview) => preview.type == type.name)
        .take(kListRowPreviewCount)
        .toList();
    if (fromCache.length >= wanted) return fromCache;

    final signature = '$name|${type.name}|${entries.join(',')}';
    final loaded = _typedPreviews[signature];
    if (loaded != null) return loaded;
    if (_requested.add(signature)) {
      provider
          .loadListPreviewsOfType(name, type, limit: kListRowPreviewCount)
          .then((previews) {
            if (mounted) setState(() => _typedPreviews[signature] = previews);
          })
          .catchError((Object error) {
            debugPrint('[ListsOverview] previews of $name failed: $error');
          });
    }
    return fromCache;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final libraryProvider = context.watch<LibraryProvider?>();
    final searchProvider =
        libraryProvider == null ? context.watch<SearchProvider>() : null;
    final dynamic provider = libraryProvider ?? searchProvider;
    final names = [
      ...provider.listNames.where((name) => name == kWatchlistName),
      ...provider.listNames.where((name) => name != kWatchlistName),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < names.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: colors.border),
                _ListRow(
                  key: ValueKey('library_list_${names[i]}'),
                  name: listDisplayName(l10n, names[i]),
                  entries: provider.getListEntriesOfType(names[i], widget.type),
                  previews: _previews(provider, names[i]),
                  onTap: () => widget.onOpenList(names[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('library_new_list'),
                onPressed: () => showCreateListDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.listsNewList,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: OutlinedButton.icon(
                key: const Key('library_import_list'),
                onPressed: () => showImportListMenu(
                  context,
                  scannerBuilder: widget.scannerBuilder,
                ),
                icon: const Icon(Icons.download, size: 18),
                label: Text(
                  l10n.commonImport,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    super.key,
    required this.name,
    required this.entries,
    required this.previews,
    required this.onTap,
  });

  final String name;
  final List<String> entries;
  final List<MediaItemPreview> previews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final series = entries
        .where((entry) => LibraryProvider.listEntryType(entry) == MediaType.tv)
        .length;
    final movies = entries.length - series;

    return Semantics(
      button: true,
      label: l10n.libraryListRowLabel(name, entries.length, movies, series),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _MiniPosters(previews: previews),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: _SplitBar(movies: movies, series: series),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entries.length}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.text2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: colors.text2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Up to three overlapping mini posters.
class _MiniPosters extends StatelessWidget {
  const _MiniPosters({required this.previews});

  final List<MediaItemPreview> previews;

  static const double _width = 30;
  static const double _height = 46;
  static const double _shift = 11;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: _width + _shift * (kListRowPreviewCount - 1),
      height: _height,
      child: previews.isEmpty
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: _width,
                height: _height,
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 16,
                  color: colors.text2,
                ),
              ),
            )
          : Stack(
              children: [
                for (var i = 0; i < previews.length; i++)
                  PositionedDirectional(
                    start: i * _shift,
                    top: 0,
                    width: _width,
                    height: _height,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.surface, width: 2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: MediaPosterCard(
                        compact: true,
                        showType: false,
                        data: MediaPosterData(
                          title: previews[i].title,
                          kind: previews[i].type == MediaType.tv.name
                              ? MediaKind.series
                              : MediaKind.movie,
                          imageUrl: previews[i].posterPath == null
                              ? null
                              : 'https://image.tmdb.org/t/p/w92${previews[i].posterPath}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Thin bar split between movies and series, in the colors of the types.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.movies, required this.series});

  final int movies;
  final int series;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 4,
          child: ColoredBox(
            color: colors.surface2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (movies > 0)
                  Expanded(
                    flex: movies,
                    child: ColoredBox(
                      key: const Key('library_split_movie'),
                      color: colors.movie,
                    ),
                  ),
                if (series > 0)
                  Expanded(
                    flex: series,
                    child: ColoredBox(
                      key: const Key('library_split_series'),
                      color: colors.series,
                    ),
                  ),
                if (movies + series == 0) const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
