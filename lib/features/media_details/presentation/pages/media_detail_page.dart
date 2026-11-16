import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_actions.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_cast.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_header.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_infos.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_movie_viewings.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_related.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_seasons.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_synopsis.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_trailers.dart';
import 'package:mediavore/features/media_details/presentation/widgets/detail/media_detail_watch_providers.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watch_next_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a piece of text (a link) through the system sheet.
typedef MediaTextShare = Future<void> Function(String text);

Future<void> _shareWithSystem(String text) =>
    SharePlus.instance.share(ShareParams(text: text));

/// Actions of the "more" menu of the detail page.
enum _MoreAction { share, exportHistory, clearHistory }

/// Detail page of a film or a series.
///
/// The page owns the data (details, seen status, seasons) and lays out the
/// section widgets of `widgets/detail/` in the order of the design: a film
/// keeps genres and synopsis first, a series shows its seasons right under
/// the action buttons.
class MediaDetailPage extends StatefulWidget {
  final MediaItem item;

  /// Replaces the system share sheet (tests).
  final MediaTextShare? onShare;

  const MediaDetailPage({super.key, required this.item, this.onShare});

  /// Name of the route pushed by [show].
  static const String routeName = '/media_details';

  /// Opens the detail page of [item] as a pushed page with a back button.
  /// Completes when the page is closed, so callers can refresh.
  static Future<void> show(BuildContext context, MediaItem item) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: routeName),
        builder: (context) => MediaDetailPage(item: item),
      ),
    );
  }

  /// Link to the TMDB page of [item].
  static String tmdbLink(MediaItem item) =>
      'https://www.themoviedb.org/${item.mediaType == MediaType.tv ? 'tv' : 'movie'}/${item.id}';

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  MediaDetails? _mediaDetails;
  bool _isLoading = true;
  int? _expandedSeason;
  final Map<int, List<dynamic>> _episodesBySeason = {};
  final Map<int, bool> _loadingSeasons = {};
  List<SeenItem> _seenStatus = [];
  bool _isOffline = false;

  // The seen counters are derived from [_seenStatus], a per-item snapshot.
  // Every seen-history mutation in [SearchProvider] (markAsSeen,
  // deleteSeenEntry, removeFromSeen, ...) ends with loadAllSeenStatus(),
  // which replaces the `seenItems` list. Listening for that replacement
  // keeps the counters in sync with every entry point (Watch Next, the
  // episode SeenManager, history deletion), see #209.
  late final SearchProvider _searchProvider;
  List<SeenItem>? _lastSeenItems;
  int _seenStatusRequest = 0;

  @override
  void initState() {
    super.initState();
    _searchProvider = context.read<SearchProvider>();
    _lastSeenItems = _searchProvider.seenItems;
    _searchProvider.addListener(_onSearchProviderChanged);
    _fetchMediaDetails();
    _fetchSeenStatus();
    _openNextSeason();
  }

  @override
  void dispose() {
    _searchProvider.removeListener(_onSearchProviderChanged);
    super.dispose();
  }

  void _onSearchProviderChanged() {
    final seenItems = _searchProvider.seenItems;
    if (identical(seenItems, _lastSeenItems)) return;
    _lastSeenItems = seenItems;
    _fetchSeenStatus();
  }

  Future<void> _fetchMediaDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      final provider = context.read<SearchProvider>();
      final details = await provider.getMediaDetails(
        widget.item.id,
        widget.item.mediaType,
      );
      if (mounted) {
        setState(() {
          _mediaDetails = details;
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOffline =
              e.toString().contains('SocketException') ||
              e.toString().contains('Network error') ||
              e.toString().contains('connectionError');
        });
      }
    }
  }

  Future<void> _fetchSeenStatus() async {
    // Only the latest request may write, so overlapping refreshes (e.g. a
    // quick double tap on Watch Next) cannot leave an older snapshot.
    final request = ++_seenStatusRequest;
    final status = await _searchProvider.loadSeenStatusForItem(
      widget.item.id,
      widget.item.mediaType,
    );
    if (mounted && request == _seenStatusRequest) {
      setState(() {
        _seenStatus = status;
      });
    }
  }

  /// Opens the season of the next episode when the series is started, so
  /// the user lands on what comes next.
  Future<void> _openNextSeason() async {
    if (widget.item.mediaType != MediaType.tv) return;
    final seen = await _searchProvider.loadSeenStatusForItem(
      widget.item.id,
      MediaType.tv,
    );
    if (seen.isEmpty) return;
    final next = await _searchProvider.getNextEpisode(widget.item.id);
    if (next == null || !mounted || _expandedSeason != null) return;
    await _fetchSeasonDetails(next.seasonNumber, silent: true);
  }

  Future<void> _fetchSeasonDetails(
    int seasonNumber, {
    bool silent = false,
  }) async {
    if (_episodesBySeason.containsKey(seasonNumber)) {
      setState(() {
        _expandedSeason = _expandedSeason == seasonNumber ? null : seasonNumber;
      });
      return;
    }

    setState(() {
      _loadingSeasons[seasonNumber] = true;
      _expandedSeason = seasonNumber;
    });

    try {
      final provider = context.read<SearchProvider>();
      final data = await provider.getSeasonDetails(
        widget.item.id,
        seasonNumber,
      );
      if (mounted) {
        setState(() {
          _episodesBySeason[seasonNumber] = data['episodes'] ?? [];
          _loadingSeasons[seasonNumber] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSeasons[seasonNumber] = false;
          _expandedSeason = null;
        });
        if (silent) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.detailOfflineSeason)),
        );
      }
    }
  }

  Future<void> _exportHistory() async {
    final provider = context.read<SearchProvider>();
    final data =
        (await provider.loadSeenStatusForItem(
              widget.item.id,
              widget.item.mediaType,
            ))
            .map(
              (entry) => {
                'id': entry.id,
                'tmdbId': entry.tmdbId,
                'type': entry.type.name,
                'title': entry.title,
                'posterPath': entry.posterPath,
                'seenDate': entry.seenDate.toIso8601String(),
                'seasonNumber': entry.seasonNumber,
                'episodeNumber': entry.episodeNumber,
                'runtime': entry.runtime,
                'genres': entry.genres,
              },
            )
            .toList();

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.detailNoHistoryToExport)),
        );
      }
      return;
    }

    final jsonString = jsonEncode(data);
    final fileName =
        'mediavore_${widget.item.title.replaceAll(' ', '_')}_history.json';

    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(context.l10n.dataSaveToDevice),
                onTap: () async {
                  Navigator.pop(context);
                  await _saveFileToDevice(context, jsonString, fileName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(context.l10n.dataShareViaSystem),
                onTap: () async {
                  Navigator.pop(context);
                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File('${tempDir.path}/$fileName');
                  await tempFile.writeAsString(jsonString);
                  await Share.shareXFiles(
                    [XFile(tempFile.path, mimeType: 'application/json')],
                    text: context.l10n.detailHistoryShareText(
                      widget.item.title,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _saveFileToDevice(
    BuildContext context,
    String jsonString,
    String fileName,
  ) async {
    try {
      final bytes = utf8.encode(jsonString);
      final result = await FilePicker.saveFile(
        dialogTitle: context.l10n.detailSaveHistoryDialog,
        fileName: fileName,
        initialDirectory: '/storage/emulated/0/Download/MediaVore',
        bytes: bytes,
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.dataFileSaved)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.detailSaveFailed('$e'))),
        );
      }
    }
  }

  void _onGenreTapped(String genreName) {
    final genreId = GenreUtils.getGenreIdByName(genreName);
    if (genreId != null) {
      final provider = context.read<SearchProvider>();
      provider.clearFilters();
      provider.setFilters(genreIds: [genreId], type: widget.item.mediaType);
      provider.searchMedia('');
      provider.setSelectedTab(AppTab.discover);

      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _showMoreMenu(MediaItem item) async {
    final l10n = context.l10n;
    final action = await showAppMenu<_MoreAction>(
      context: context,
      title: item.title,
      items: [
        AppMenuItem(
          value: _MoreAction.share,
          label: l10n.detailShare,
          subtitle: l10n.detailShareHint,
          icon: Icons.share,
        ),
        AppMenuItem(
          value: _MoreAction.exportHistory,
          label: l10n.detailExportHistory,
          icon: Icons.file_upload_outlined,
        ),
        if (_seenStatus.isNotEmpty)
          AppMenuItem(
            value: _MoreAction.clearHistory,
            label: l10n.seenClearHistory,
            icon: Icons.delete_outline,
            danger: true,
          ),
      ],
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _MoreAction.share:
        await (widget.onShare ?? _shareWithSystem)(
          MediaDetailPage.tmdbLink(item),
        );
      case _MoreAction.exportHistory:
        await _exportHistory();
      case _MoreAction.clearHistory:
        await _confirmClearHistory(item);
    }
  }

  /// Removing viewings is never a single gesture: menu, then confirmation.
  Future<void> _confirmClearHistory(MediaItem item) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: l10n.seenClearHistory,
      message: l10n.seenClearHistoryMessage(item.title),
      actions: [
        AppDialogAction(label: l10n.commonCancel),
        AppDialogAction(label: l10n.seenClearAll, value: true, danger: true),
      ],
    );
    if (confirmed != true || !mounted) return;
    await _searchProvider.removeFromSeen(item.id, item.mediaType);
  }

  void _openRelated(MediaItem item) => MediaDetailPage.show(context, item);

  @override
  Widget build(BuildContext context) {
    final item = _mediaDetails?.item ?? widget.item;
    final details = _mediaDetails;
    final l10n = context.l10n;
    final isTv = item.mediaType == MediaType.tv;
    final provider = context.watch<SearchProvider>();
    final inLists = provider.listNames
        .where((name) => provider.isItemInList(item, name))
        .map((name) => listDisplayName(l10n, name))
        .toList();

    const gap = SizedBox(height: 16);
    final seasons =
        isTv && (item.seasons != null || item.numberOfEpisodes != null)
        ? MediaDetailSeasons(
            item: item,
            seenStatus: _seenStatus,
            expandedSeason: _expandedSeason,
            episodesBySeason: _episodesBySeason,
            loadingSeasons: _loadingSeasons,
            onToggleSeason: _fetchSeasonDetails,
          )
        : null;

    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
        slivers: [
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  MediaDetailHeader(
                    item: item,
                    seenStatus: _seenStatus,
                    showDetails: !_isOffline,
                    onMore: () => _showMoreMenu(item),
                  ),
                  if (_isOffline) ...[
                    gap,
                    OfflineBanner(
                      title: l10n.detailOfflineMode,
                      message: l10n.detailOfflineMessage,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: _fetchMediaDetails,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.commonTryAgain),
                      ),
                    ),
                  ],
                  gap,
                  MediaDetailActions(
                    item: item,
                    primary: isTv
                        ? null
                        : SeenManager(
                            key: ValueKey('seen_movie_${item.id}'),
                            item: item,
                            primary: true,
                          ),
                  ),
                  if (!isTv) MediaDetailMovieViewings(item: item),
                  if (isTv) WatchNextButton(item: item),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // A series shows its seasons before anything else.
                    ?seasons,
                    if (!_isOffline) ...[
                      if (item.genres != null && item.genres!.isNotEmpty) ...[
                        gap,
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final genre in item.genres!)
                              ActionChip(
                                label: Text(
                                  genre,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _onGenreTapped(genre),
                              ),
                          ],
                        ),
                      ],
                      if (details?.watchProviders != null)
                        MediaDetailWatchProviders(
                          watchProviders: details!.watchProviders,
                        ),
                      MediaDetailSynopsis(text: item.overview),
                      MediaDetailTrailers(
                        videos: details?.videos,
                        onOpen: widget.onShare ?? _shareWithSystem,
                      ),
                      MediaDetailInfos(
                        item: item,
                        director: details?.director,
                        directorName: details?.director?.name,
                      ),
                    ],
                    if (details != null) ...[
                      MediaDetailCast(cast: details.cast),
                      MediaDetailRelated(
                        title: l10n.detailSimilar,
                        items: details.similar,
                        onOpen: _openRelated,
                      ),
                      MediaDetailRelated(
                        title: l10n.detailRecommendations,
                        items: details.recommendations,
                        onOpen: _openRelated,
                      ),
                    ],
                    if (inLists.isNotEmpty) ...[
                      gap,
                      Text(
                        l10n.detailInYourLists(inLists.join(', ')),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.text2,
                        ),
                      ),
                    ],
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
