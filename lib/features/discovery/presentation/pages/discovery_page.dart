import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/discovery/presentation/pages/swiper_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';
import 'package:mediavore/features/discovery/presentation/widgets/because_you_row.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/active_filter_chips.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';
import 'package:mediavore/features/search/presentation/widgets/search_filter_sheet.dart';
import 'package:mediavore/features/search/presentation/widgets/search_people_row.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Discover tab: Explore (permanent search, type chips, trends of the week or
/// results in a 3-column grid) or Swipe.
class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  /// Columns of the grid.
  static const int columns = 3;

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  static const double _gutter = 16;

  late final TextEditingController _controller;
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  late final SettingsProvider _settings;
  late String _credential;

  @override
  void initState() {
    super.initState();
    // The query survives a rebuild of the tab.
    _controller = TextEditingController(
      text: context.read<SearchProvider>().currentQuery,
    );
    _scrollController.addListener(_onScroll);
    // Reload once a TMDB credential is saved (first-launch screen or
    // Settings), so a stale "missing key" error doesn't stay on screen.
    _settings = context.read<SettingsProvider>();
    _credential = _settings.tmdbApiKey;
    _settings.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDiscovery();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().fetchNextPage();
    }
  }

  void _onSettingsChanged() {
    final credential = _settings.tmdbApiKey;
    if (credential == _credential) return;
    _credential = credential;
    if (credential.isNotEmpty && mounted) _refreshDiscovery();
  }

  void _refreshDiscovery([String? query]) {
    final provider = context.read<SearchProvider>();
    final q = query ?? _controller.text;
    provider.searchMedia(q);
    if (q.isEmpty) {
      provider.loadBecauseYouRecommendations(forceRefresh: true);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refreshDiscovery(value);
    });
  }

  void _openFilterDialog() async {
    final provider = context.read<SearchProvider>();
    await SearchFilterSheet.show(
      context,
      initialFilters: provider.filters,
      onApply: (newFilters) {
        provider.setFilters(filters: newFilters);
        _refreshDiscovery();
      },
    );
  }

  void _selectType(MediaType? type) {
    final provider = context.read<SearchProvider>();
    if (provider.filterType == type) return;
    provider.setFilters(filters: provider.filters.copyWith(type: () => type));
    _refreshDiscovery();
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    _refreshDiscovery('');
  }

  /// State shown instead of the grid when the first page failed to load.
  Widget _buildErrorState(SearchProvider provider) {
    final errorType = provider.errorType!;
    final needsApiKey =
        errorType == SearchErrorType.missingApiKey ||
        errorType == SearchErrorType.invalidApiKey;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(switch (errorType) {
            SearchErrorType.missingApiKey ||
            SearchErrorType.invalidApiKey => Icons.key_off,
            SearchErrorType.offline => Icons.wifi_off,
            SearchErrorType.server ||
            SearchErrorType.unknown => Icons.cloud_off,
          }, size: 48),
          const SizedBox(height: 16),
          Text(
            searchErrorMessage(errorType, context.l10n),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (needsApiKey)
            FilledButton.icon(
              key: const Key('discovery_connect_tmdb'),
              icon: const Icon(Icons.link),
              label: Text(context.l10n.discoverConnectTmdb),
              // Saving a key reloads via _onSettingsChanged.
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const TmdbCredentialPage(),
                ),
              ),
            )
          else
            FilledButton.icon(
              key: const Key('discovery_retry'),
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
              onPressed: _refreshDiscovery,
            ),
        ],
      ),
    );
  }

  /// Trailing grid cell: spinner while loading the next page, or a retry
  /// button when that load failed.
  Widget _buildListFooter(SearchProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: TextButton.icon(
        key: const Key('discovery_retry_next_page'),
        icon: const Icon(Icons.refresh),
        label: Text(context.l10n.commonRetry),
        onPressed: provider.retryNextPage,
      ),
    );
  }

  Widget _buildSearchRow(AppLocalizations l10n) {
    final colors = context.appColors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: l10n.discoverSearchLabel,
            child: TextField(
              key: const Key('discovery_search_field'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                _refreshDiscovery(value);
              },
              decoration: InputDecoration(
                hintText: kDiscoverShowBooks
                    ? l10n.discoverSearchHintWithBooks
                    : l10n.discoverSearchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          key: const Key('discovery_search_clear'),
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: l10n.discoverSearchClear,
                          onPressed: _clearQuery,
                        ),
                ),
                filled: true,
                fillColor: colors.surface,
                isDense: true,
                constraints: const BoxConstraints(minHeight: kMinTapTarget),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: colors.stateOutline, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Consumer<SearchProvider>(
          builder: (context, provider, _) {
            final count = provider.filters.activeCount;
            return IconButton.outlined(
              key: const Key('discovery_filters'),
              constraints: const BoxConstraints(
                minWidth: kMinTapTarget,
                minHeight: kMinTapTarget,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.tune, size: 20),
              ),
              tooltip: l10n.discoveryFiltersTitle,
              onPressed: _openFilterDialog,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeChips(AppLocalizations l10n, MediaType? selected) {
    return FilterChipRow(
      chips: [
        AppFilterChip(
          label: l10n.discoverTypeAll,
          selected: selected == null,
          onTap: () => _selectType(null),
        ),
        AppFilterChip(
          label: l10n.discoverTypeFilms,
          selected: selected == MediaType.movie,
          onTap: () => _selectType(MediaType.movie),
        ),
        AppFilterChip(
          label: l10n.discoverTypeSeries,
          selected: selected == MediaType.tv,
          onTap: () => _selectType(MediaType.tv),
        ),
        // Books: hidden until their search exists (kDiscoverShowBooks).
        if (kDiscoverShowBooks)
          AppFilterChip(label: l10n.discoverTypeBooks, onTap: null),
      ],
    );
  }

  String _resultsTitle(AppLocalizations l10n, SearchProvider provider) {
    if (provider.isTrending) return l10n.discoverTrendingWeek;
    // The total is only known once the last page is loaded.
    return provider.hasMore && provider.items.isNotEmpty
        ? l10n.discoverResults
        : l10n.discoverResultsCount(provider.items.length);
  }

  List<Widget> _buildResults(AppLocalizations l10n, SearchProvider provider) {
    final items = provider.items;

    if (provider.isLoading && items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (items.isEmpty && provider.errorType != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildErrorState(provider),
        ),
      ];
    }

    final peopleSliver = provider.peopleResults.isNotEmpty
        ? SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 0),
            sliver: SliverToBoxAdapter(
              child: SearchPeopleRow(people: provider.peopleResults),
            ),
          )
        : null;

    final becauseYouSliver =
        (provider.isTrending &&
            !provider.isOffline &&
            provider.becauseYouData != null &&
            provider.becauseYouData!.items.length >= 3)
        ? SliverPadding(
            padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 0),
            sliver: SliverToBoxAdapter(
              child: BecauseYouRow(data: provider.becauseYouData!),
            ),
          )
        : null;

    final header = SliverPadding(
      padding: const EdgeInsets.fromLTRB(_gutter, 8, _gutter, 0),
      sliver: SliverToBoxAdapter(
        child: SectionHeader(
          key: const Key('discovery_results_title'),
          title: _resultsTitle(l10n, provider),
        ),
      ),
    );

    if (items.isEmpty) {
      final query = provider.currentQuery;
      return [
        if (peopleSliver != null) peopleSliver,
        if (becauseYouSliver != null) becauseYouSliver,
        header,
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.isEmpty
                      ? l10n.discoverNoResults
                      : l10n.discoverNoResultsFor(query),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appColors.text2,
                  ),
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('discovery_clear_filters'),
                    onPressed: () {
                      provider.clearFilters();
                      _refreshDiscovery();
                    },
                    child: Text(l10n.discoveryClearFilters),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    final hasFooter = provider.isLoading || provider.errorType != null;

    return [
      if (peopleSliver != null) peopleSliver,
      if (becauseYouSliver != null) becauseYouSliver,
      header,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 24),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) => SliverGrid(
            gridDelegate: MediaPosterCard.gridDelegate(
              context: context,
              width: constraints.crossAxisExtent,
              crossAxisCount: DiscoveryPage.columns,
            ),
            delegate: SliverChildBuilderDelegate(
              childCount: items.length + (hasFooter ? 1 : 0),
              (context, index) {
                if (index == items.length) return _buildListFooter(provider);

                final item = items[index];
                return MediaPosterCard(
                  data: mediaItemPosterData(
                    context,
                    item,
                    seenCount: provider.getSeenCount(item),
                    liked: provider.isLiked(item),
                  ),
                  onTap: () => MediaDetailPage.show(context, item),
                  action: WatchlistIconButton(
                    item: item,
                    iconSize: 18,
                    onImage: true,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildModeSegment(AppLocalizations l10n, DiscoverMode mode) {
    return AppSegmented<DiscoverMode>(
      segments: [
        AppSegment(
          value: DiscoverMode.explore,
          label: l10n.discoverModeExplore,
          icon: Icons.search,
        ),
        AppSegment(
          value: DiscoverMode.swipe,
          label: l10n.discoverModeSwipe,
          icon: Icons.style_outlined,
        ),
      ],
      selected: mode,
      onChanged: context.read<DiscoveryProvider>().setMode,
    );
  }

  Widget _buildTitle(AppLocalizations l10n) => Semantics(
    header: true,
    child: Text(
      l10n.discoveryTitle,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSwipeEnabled = context.watch<SettingsProvider>().isSwipeModeEnabled;
    final rawMode = context.watch<DiscoveryProvider>().mode;
    final mode = isSwipeEnabled ? rawMode : DiscoverMode.explore;

    if (mode == DiscoverMode.swipe && isSwipeEnabled) {
      return ColoredBox(
        color: context.appColors.bg,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(l10n),
                const SizedBox(height: 8),
                _buildModeSegment(l10n, mode),
                const Expanded(child: SwiperPage()),
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<SearchProvider>();

    return ColoredBox(
      color: context.appColors.bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _refreshDiscovery(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // Scrolling the results puts the keyboard away.
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 0),
                sliver: SliverList.list(
                  children: [
                    _buildTitle(l10n),
                    if (isSwipeEnabled) ...[
                      const SizedBox(height: 8),
                      _buildModeSegment(l10n, mode),
                    ],
                    if (provider.isOffline) ...[
                      const SizedBox(height: 8),
                      OfflineBanner(message: l10n.discoverOfflineMessage),
                    ],
                    const SizedBox(height: 8),
                    _buildSearchRow(l10n),
                    const SizedBox(height: 4),
                    _buildTypeChips(l10n, provider.filterType),
                    if (provider.filters.hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      ActiveFilterChips(
                        filters: provider.filters,
                        onFilterChanged: (newFilters) {
                          provider.setFilters(filters: newFilters);
                          _refreshDiscovery();
                        },
                        onClearAll: () {
                          provider.clearFilters();
                          _controller.clear();
                          _refreshDiscovery();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              ..._buildResults(l10n, provider),
            ],
          ),
        ),
      ),
    );
  }
}
