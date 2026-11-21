import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/notification_center_filter.dart';
import 'package:mediavore/core/utils/release_groups.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/offline_banner.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/home/presentation/in_progress_actions.dart';
import 'package:mediavore/features/home/presentation/pages/in_progress_page.dart';
import 'package:mediavore/features/home/presentation/pages/upcoming_page.dart';
import 'package:mediavore/features/home/presentation/widgets/connect_tmdb_card.dart';
import 'package:mediavore/features/home/presentation/widgets/home_link_row.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_card.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_thumbnail.dart';
import 'package:mediavore/features/home/presentation/widgets/upcoming_rows_card.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Home tab, "Tonight": what to resume, what to watch tonight, what else is
/// in progress.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showTogetherLink = kShowTogetherTab,
    this.clock = DateTime.now,
  });

  /// Shows "Choose together", which leads to the Together tab; off when
  /// that tab is not part of the shell.
  final bool showTogetherLink;

  /// Current time; overridable for tests.
  final DateTime Function() clock;

  /// Cards of "Resume".
  static const int resumeCount = 3;

  /// Thumbnails of "Also in progress" before the "+n" tile.
  static const int alsoInProgressCount = 10;

  /// Releases of "Upcoming" before "See all".
  static const int upcomingCount = 5;

  /// Posters of "To watch tonight".
  static const int tonightCount = 3;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _gutter = 16;
  static const double _sectionGap = 20;

  /// `null` = all kinds.
  MediaKind? _kindFilter;
  int _tonightOffset = 0;

  /// Series whose next episode is being marked as seen.
  final Set<int> _marking = {};
  bool _isRefreshing = false;

  // In progress only holds series until books land (#325).
  MediaKind _kindOf(InProgressItem item) => MediaKind.series;

  Future<void> _refresh() async {
    final provider = context.read<SearchProvider>();
    if (_isRefreshing || provider.isNotifiedRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final hasTmdbKey = context.read<SettingsProvider>().tmdbApiKey.isNotEmpty;
      if (hasTmdbKey) {
        await provider.refreshNotifiedItems(force: true);
      }
      await provider.reloadSavedTitles();
      await provider.refreshQuickAddItems();
    } catch (e) {
      debugPrint('[HomePage] refresh failed: $e');
      if (mounted) {
        showAppMessage(
          provider.isOffline
              ? context.l10n.searchErrorOffline
              : context.l10n.searchErrorUnknown,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _markSeen(InProgressItem item) async {
    if (!_marking.add(item.tmdbId)) return;
    setState(() {});
    try {
      await markInProgressEpisodeSeen(context, item);
    } finally {
      _marking.remove(item.tmdbId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openSeries(InProgressItem item) =>
      openInProgressSeries(context, item);

  void _openInProgress({bool pausedOnly = false}) =>
      InProgressPage.show(context, pausedOnly: pausedOnly);

  void _openTmdbCredential() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TmdbCredentialPage()));
  }

  String _listLabel(AppLocalizations l10n, String name) =>
      name == 'watchlist' ? l10n.listsWatchlist : name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<SearchProvider>();
    final hasTmdbKey = context.select<SettingsProvider, bool>(
      (settings) => settings.tmdbApiKey.isNotEmpty,
    );
    final debug = context.select<SettingsProvider, bool>(
      (settings) => settings.notificationCenterDebug,
    );
    final now = widget.clock();

    final inProgress = provider.inProgressItems;
    final active = [
      for (final item in inProgress)
        if (!item.paused) item,
    ];
    final pausedCount = inProgress.length - active.length;
    final resume = active.take(HomePage.resumeCount).toList();
    final others = active.skip(HomePage.resumeCount).toList();

    final candidates = provider.tonightCandidates;
    final picks = rotatingPicks(candidates, _tonightOffset);
    final listLabel = _listLabel(l10n, provider.tonightListName);

    final sections = <Widget>[
      if (provider.isOffline) OfflineBanner(message: l10n.homeOfflineMessage),
      if (resume.isNotEmpty) _buildResume(l10n, resume),
      if (picks.isNotEmpty)
        _buildTonight(l10n, provider, candidates, picks, listLabel),
      if (!hasTmdbKey)
        ConnectTmdbCard(onConnect: _openTmdbCredential)
      else if (resume.isEmpty && picks.isEmpty)
        _buildEmpty(l10n, listLabel),
      if (others.isNotEmpty)
        _buildAlsoInProgress(l10n, active.length, others, now),
      if (pausedCount > 0)
        HomeLinkRow(
          key: const Key('home_paused'),
          icon: Icons.schedule,
          title: l10n.homePausedTitle(pausedCount),
          subtitle: l10n.homePausedSubtitle(InProgressItem.pauseAfter.inDays),
          onTap: () => _openInProgress(pausedOnly: true),
        ),
      // Releases need the network: the TMDB card stands in without a key.
      if (hasTmdbKey) _buildUpcoming(l10n, provider, now, debug: debug),
    ];

    return ColoredBox(
      color: context.appColors.bg,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(_gutter, 12, _gutter, 24),
            children: [
              _buildHeader(l10n, provider, now, canRefresh: true),
              for (final section in sections) ...[
                const SizedBox(height: _sectionGap),
                section,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppLocalizations l10n,
    SearchProvider provider,
    DateTime now, {
    required bool canRefresh,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final date = formatHomeDate(l10n, now);
    final refreshing = _isRefreshing || provider.isNotifiedRefreshing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: textTheme.bodySmall?.copyWith(fontSize: 13)),
              Semantics(
                header: true,
                child: Text(l10n.homeTitle, style: textTheme.headlineMedium),
              ),
            ],
          ),
        ),
        if (canRefresh)
          IconButton(
            key: const Key('home_refresh'),
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            tooltip: l10n.commonRefresh,
            onPressed: refreshing ? null : _refresh,
            icon: refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
          ),
      ],
    );
  }

  Widget _buildResume(AppLocalizations l10n, List<InProgressItem> resume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeResume),
        for (var i = 0; i < resume.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          InProgressCard(
            key: ValueKey('home_resume_${resume[i].tmdbId}'),
            item: resume[i],
            onOpen: () => _openSeries(resume[i]),
            onMarkSeen: _marking.contains(resume[i].tmdbId)
                ? null
                : () => _markSeen(resume[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildTonight(
    AppLocalizations l10n,
    SearchProvider provider,
    List<MediaItem> candidates,
    List<MediaItem> picks,
    String listLabel,
  ) {
    return Column(
      key: const Key('home_tonight'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.homeTonightTitle,
          actionLabel: l10n.homeTonightOtherIdea,
          onAction: candidates.length > HomePage.tonightCount
              ? () => setState(() => _tonightOffset += HomePage.tonightCount)
              : null,
        ),
        Text(
          l10n.homeTonightSource(listLabel, candidates.length),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: MediaPosterCard.gridDelegate(
              context: context,
              width: constraints.maxWidth,
              crossAxisCount: HomePage.tonightCount,
            ),
            children: [
              for (final item in picks)
                MediaPosterCard(
                  key: ValueKey(
                    'home_tonight_${item.mediaType.name}_${item.id}',
                  ),
                  data: mediaItemPosterData(
                    context,
                    item,
                    seenCount: 0,
                    liked: provider.isLiked(item),
                  ),
                  onTap: () => MediaDetailPage.show(context, item),
                ),
            ],
          ),
        ),
        if (widget.showTogetherLink) ...[
          const SizedBox(height: 10),
          HomeLinkRow(
            key: const Key('home_choose_together'),
            icon: Icons.group_outlined,
            title: l10n.homeChooseTogether,
            subtitle: l10n.homeChooseTogetherSubtitle,
            onTap: () => provider.setSelectedTab(AppTab.together),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n, String listLabel) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      key: const Key('home_empty'),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.homeEmptyTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeEmptyMessage(listLabel),
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () =>
                context.read<SearchProvider>().setSelectedTab(AppTab.discover),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: Text(l10n.homeEmptyAction),
          ),
        ],
      ),
    );
  }

  String _filterLabel(AppLocalizations l10n, MediaKind kind, int count) =>
      switch (kind) {
        MediaKind.series => l10n.homeFilterSeries(count),
        MediaKind.book => l10n.homeFilterBooks(count),
        MediaKind.movie => '${kind.label(l10n)} · $count',
      };

  Widget _buildAlsoInProgress(
    AppLocalizations l10n,
    int activeCount,
    List<InProgressItem> others,
    DateTime now,
  ) {
    final filterKinds = progressFilterKinds(others.map(_kindOf));
    final filter = filterKinds.contains(_kindFilter) ? _kindFilter : null;
    final shown = [
      for (final item in others)
        if (filter == null || _kindOf(item) == filter) item,
    ];
    final thumbnails = shown.take(HomePage.alsoInProgressCount).toList();
    final hidden = shown.length - thumbnails.length;

    return Column(
      key: const Key('home_also_in_progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.homeAlsoInProgress(others.length),
          actionLabel: l10n.homeSeeAllCount(activeCount),
          onAction: _openInProgress,
        ),
        if (filterKinds.isNotEmpty) ...[
          FilterChipRow(
            chips: [
              AppFilterChip(
                label: l10n.homeFilterAll(others.length),
                selected: filter == null,
                onTap: () => setState(() => _kindFilter = null),
              ),
              for (final kind in filterKinds)
                AppFilterChip(
                  label: _filterLabel(
                    l10n,
                    kind,
                    others.where((item) => _kindOf(item) == kind).length,
                  ),
                  selected: filter == kind,
                  onTap: () => setState(() => _kindFilter = kind),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (thumbnails.isEmpty)
          Text(
            l10n.homeRecentAreInResume,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // Scrolls edge to edge, past the page gutter.
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < thumbnails.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  InProgressThumbnail(
                    key: ValueKey('home_thumbnail_${thumbnails[i].tmdbId}'),
                    item: thumbnails[i],
                    now: now,
                    onOpen: () => _openSeries(thumbnails[i]),
                  ),
                ],
                if (hidden > 0) ...[
                  const SizedBox(width: 10),
                  MoreInProgressTile(
                    key: const Key('home_more_in_progress'),
                    count: hidden,
                    onTap: _openInProgress,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _periodLabel(AppLocalizations l10n, ReleasePeriod period) =>
      switch (period) {
        ReleasePeriod.released => l10n.upcomingGroupReleased,
        ReleasePeriod.thisWeek => l10n.upcomingGroupThisWeek,
        ReleasePeriod.thisMonth => l10n.upcomingGroupThisMonth,
        ReleasePeriod.later => l10n.upcomingGroupLater,
      };

  /// "Upcoming": at most [HomePage.upcomingCount] releases grouped by
  /// period, each group with its full count, then the rows leading to the
  /// full page.
  Widget _buildUpcoming(
    AppLocalizations l10n,
    SearchProvider provider,
    DateTime now, {
    required bool debug,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final filtered = filterReleases(
      items: provider.notifiedItems,
      seenItems: provider.seenItems,
      now: now,
    );
    final groups = groupReleases(filtered.visible, now: now);
    void open() => UpcomingPage.show(context);

    var left = HomePage.upcomingCount;
    final blocks = <Widget>[];
    for (final period in ReleasePeriod.values) {
      final items = groups.of(period);
      final shown = items.take(left).toList();
      if (shown.isEmpty) continue;
      left -= shown.length;
      blocks.addAll([
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text(
            l10n.upcomingGroupCount(_periodLabel(l10n, period), items.length),
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        UpcomingRowsCard(
          key: ValueKey('home_upcoming_${period.name}'),
          items: shown,
          now: now,
        ),
        const SizedBox(height: 6),
      ]);
    }

    return Column(
      key: const Key('home_upcoming'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.upcomingTitle(groups.datedCount),
          onAction: groups.datedCount > HomePage.upcomingCount ? open : null,
        ),
        if (blocks.isEmpty)
          Text(
            '${l10n.notifNoReleases} ${l10n.notifNoReleasesHint}',
            style: textTheme.bodySmall,
          )
        else
          ...blocks,
        if (groups.undated.isNotEmpty) ...[
          const SizedBox(height: 4),
          HomeLinkRow(
            key: const Key('home_upcoming_undated'),
            icon: Icons.schedule,
            title: l10n.upcomingUndatedRow(groups.undated.length),
            subtitle: l10n.upcomingUndatedRowSubtitle,
            onTap: open,
          ),
        ],
        if (debug) ...[
          const SizedBox(height: 10),
          HomeLinkRow(
            key: const Key('home_upcoming_debug'),
            icon: Icons.bug_report_outlined,
            title: l10n.upcomingDebugRow(filtered.omitted.length),
            subtitle: l10n.upcomingDebugRowSubtitle,
            onTap: open,
          ),
        ],
      ],
    );
  }
}
