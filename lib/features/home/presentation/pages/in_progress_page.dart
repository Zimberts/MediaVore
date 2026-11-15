import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/home/presentation/in_progress_actions.dart';
import 'package:mediavore/features/home/presentation/in_progress_sort.dart';
import 'package:mediavore/features/home/presentation/providers/home_session_provider.dart';
import 'package:mediavore/features/home/presentation/widgets/debug_omissions_section.dart';
import 'package:mediavore/features/home/presentation/widgets/in_progress_row.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

enum _RowAction { removeFromQuickAdd, openDetails }

/// Full list of the titles in progress, opened from "See all" on Home:
/// kind and "Paused" filters, three sorts, the series removed from Quick Add
/// and, with the notification debug setting, the missing episodes.
///
/// Filters and sort live in [HomeSessionProvider]: they are kept for the
/// session.
class InProgressPage extends StatefulWidget {
  const InProgressPage({super.key, this.clock = DateTime.now});

  /// Current time; overridable for tests.
  final DateTime Function() clock;

  /// Opens the page; [pausedOnly] preselects (or clears) the "Paused" filter.
  static Future<void> show(BuildContext context, {bool pausedOnly = false}) {
    context.read<HomeSessionProvider>().setInProgressPausedOnly(pausedOnly);
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const InProgressPage()));
  }

  @override
  State<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends State<InProgressPage> {
  static const double _gutter = 16;

  /// Series whose next episode is being marked as seen.
  final Set<int> _marking = {};

  /// Opt-outs being restored.
  final Set<QuickAddOptOut> _restoring = {};

  /// Series swiped away whose removal is not stored yet: a dismissed row
  /// must leave the tree at once.
  final Set<int> _dismissed = {};

  bool _debugLoadRequested = false;

  // In progress only holds series until books land (#325).
  MediaKind _kindOf(InProgressItem item) => MediaKind.series;

  Future<void> _refresh() async {
    final provider = context.read<SearchProvider>();
    final debug = context.read<SettingsProvider>().notificationCenterDebug;
    if (provider.isNotifiedRefreshing) return;
    try {
      await provider.refreshNotifiedItems();
      await provider.loadAllSeenStatus();
      await provider.refreshQuickAddItems();
      await provider.loadQuickAddItems();
      if (debug) await provider.loadQuickAddOmissions();
    } catch (e) {
      debugPrint('[InProgressPage] refresh failed: $e');
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

  Future<void> _openMenu(InProgressItem item) async {
    final l10n = context.l10n;
    final action = await showAppMenu<_RowAction>(
      context: context,
      title: item.title ?? l10n.commonUnknown,
      items: [
        AppMenuItem(
          value: _RowAction.removeFromQuickAdd,
          icon: Icons.close,
          label: l10n.inProgressRemoveFromQuickAdd,
          subtitle: l10n.inProgressRemoveFromQuickAddSubtitle,
        ),
        AppMenuItem(
          value: _RowAction.openDetails,
          icon: Icons.tv,
          label: l10n.inProgressOpenDetails,
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _RowAction.removeFromQuickAdd:
        await removeInProgressFromQuickAdd(context, item);
      case _RowAction.openDetails:
        await openInProgressSeries(context, item);
    }
  }

  Future<void> _dismiss(InProgressItem item) async {
    setState(() => _dismissed.add(item.tmdbId));
    try {
      await removeInProgressFromQuickAdd(context, item);
    } finally {
      _dismissed.remove(item.tmdbId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _restore(QuickAddOptOut optOut) async {
    if (!_restoring.add(optOut)) return;
    setState(() {});
    final l10n = context.l10n;
    try {
      await context.read<SearchProvider>().restoreQuickAddOptOut(optOut);
      showAppMessage(l10n.inProgressRestoredMessage);
    } catch (e) {
      debugPrint('[InProgressPage] restore failed: $e');
    } finally {
      _restoring.remove(optOut);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final provider = context.watch<SearchProvider>();
    final session = context.watch<HomeSessionProvider>();
    final debug = context.select<SettingsProvider, bool>(
      (settings) => settings.notificationCenterDebug,
    );
    final now = widget.clock();

    // Lazily compute the diagnostics once when debug is enabled.
    if (debug && !_debugLoadRequested) {
      _debugLoadRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<SearchProvider>().loadQuickAddOmissions();
      });
    }

    final all = provider.inProgressItems;
    final pausedCount = all.where((item) => item.paused).length;
    final filterKinds = progressFilterKinds(all.map(_kindOf));
    final kind = filterKinds.contains(session.inProgressKind)
        ? session.inProgressKind
        : null;
    final pausedOnly = session.inProgressPausedOnly;
    final shown = sortInProgress(
      all.where(
        (item) =>
            !_dismissed.contains(item.tmdbId) &&
            (kind == null || _kindOf(item) == kind) &&
            (!pausedOnly || item.paused),
      ),
      session.inProgressSort,
    );

    // An opt-out left behind by an episode that was watched anyway no longer
    // hides its series: only list the series that are really out.
    final inProgressIds = {for (final item in all) item.tmdbId};
    final optOuts = [
      for (final optOut in provider.quickAddOptOuts)
        if (!inProgressIds.contains(optOut.tmdbId)) optOut,
    ];

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.inProgressTitle(all.length))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 96),
          children: [
            FilterChipRow(
              key: const Key('in_progress_filters'),
              chips: [
                if (filterKinds.isNotEmpty) ...[
                  AppFilterChip(
                    label: l10n.discoverTypeAll,
                    selected: kind == null,
                    onTap: () => session.setInProgressKind(null),
                  ),
                  for (final filterKind in filterKinds)
                    AppFilterChip(
                      label: _kindLabel(l10n, filterKind),
                      selected: kind == filterKind,
                      onTap: () => session.setInProgressKind(filterKind),
                    ),
                ],
                AppFilterChip(
                  icon: Icons.schedule,
                  label: l10n.inProgressPausedChip(pausedCount),
                  selected: pausedOnly,
                  onTap: () => session.setInProgressPausedOnly(!pausedOnly),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppSegmented<InProgressSort>(
              key: const Key('in_progress_sort'),
              selected: session.inProgressSort,
              onChanged: session.setInProgressSort,
              segments: [
                AppSegment(
                  value: InProgressSort.recent,
                  label: l10n.inProgressSortRecent,
                ),
                AppSegment(
                  value: InProgressSort.almostDone,
                  label: l10n.inProgressSortAlmostDone,
                ),
                AppSegment(
                  value: InProgressSort.alphabetical,
                  label: l10n.inProgressSortAlphabetical,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              Padding(
                key: const Key('in_progress_empty'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  all.isEmpty
                      ? l10n.notifNoNextEpisodes
                      : l10n.inProgressEmptyFiltered,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.text2),
                ),
              )
            else
              AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.border),
                      _buildRow(shown[i], now),
                    ],
                  ],
                ),
              ),
            if (optOuts.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildOptOuts(l10n, optOuts),
            ],
            if (debug) ...[
              const SizedBox(height: 20),
              _buildDebug(l10n, provider),
            ],
          ],
        ),
      ),
    );
  }

  String _kindLabel(AppLocalizations l10n, MediaKind kind) => switch (kind) {
    MediaKind.movie => l10n.discoverTypeFilms,
    MediaKind.series => l10n.discoverTypeSeries,
    MediaKind.book => l10n.discoverTypeBooks,
  };

  Widget _buildRow(InProgressItem item, DateTime now) {
    final colors = context.appColors;
    final next = item.next;
    return Dismissible(
      // A restored or re-queued entry is a new row.
      key: ValueKey(
        'in_progress_${item.tmdbId}-${next.seasonNumber}-'
        '${next.episodeNumber}-${next.insertedAt.millisecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colors.danger,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.close, color: colors.onDanger),
      ),
      onDismissed: (_) => _dismiss(item),
      child: InProgressRow(
        key: ValueKey('in_progress_row_${item.tmdbId}'),
        item: item,
        now: now,
        onOpen: () => openInProgressSeries(context, item),
        onMarkSeen: _marking.contains(item.tmdbId)
            ? null
            : () => _markSeen(item),
        onMenu: () => _openMenu(item),
      ),
    );
  }

  Widget _buildOptOuts(AppLocalizations l10n, List<QuickAddOptOut> optOuts) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('in_progress_opt_outs'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.inProgressRemovedSection(optOuts.length)),
        AppCard(
          padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < optOuts.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                _buildOptOut(l10n, textTheme, optOuts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptOut(
    AppLocalizations l10n,
    TextTheme textTheme,
    QuickAddOptOut optOut,
  ) {
    final title = optOut.title ?? l10n.commonUnknown;
    final season = optOut.seasonNumber;
    final episode = optOut.episodeNumber;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (season != null && episode != null)
                    Text(
                      l10n.homeEpisodeCode(season, episode),
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: ValueKey(
              'in_progress_restore_${optOut.tmdbId}-$season-$episode',
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            ),
            onPressed: _restoring.contains(optOut)
                ? null
                : () => _restore(optOut),
            child: Text(
              l10n.inProgressRestore,
              semanticsLabel: l10n.inProgressRestoreLabel(title),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebug(AppLocalizations l10n, SearchProvider provider) {
    final omissions = provider.quickAddOmissions;

    DebugOmissionGroup group(String reason, QuickAddOmissionReason value) =>
        DebugOmissionGroup(
          reason: reason,
          entries: [
            for (final omission in omissions)
              if (omission.reason == value)
                DebugOmissionEntry(
                  title: _omissionTitle(l10n, omission),
                  detail: _omissionDetail(l10n, omission),
                ),
          ],
        );

    return DebugOmissionsSection(
      key: const Key('in_progress_debug'),
      title: l10n.debugMissingEpisodesTitle,
      subtitle: l10n.debugMissingEpisodesSubtitle,
      loading: provider.isQuickAddOmissionsLoading,
      actionLabel: l10n.debugRecompute,
      onAction: () => provider.loadQuickAddOmissions(allowFetch: true),
      groups: [
        group(l10n.debugQuickAddOptedOut, QuickAddOmissionReason.optedOut),
        group(
          l10n.debugQuickAddNotReleased,
          QuickAddOmissionReason.notReleased,
        ),
        group(
          l10n.debugQuickAddNotPopulated,
          QuickAddOmissionReason.notPopulated,
        ),
        group(l10n.debugQuickAddNoAirDate, QuickAddOmissionReason.noAirDate),
        group(
          l10n.debugQuickAddNoCacheData,
          QuickAddOmissionReason.noCacheData,
        ),
      ],
    );
  }

  String _omissionTitle(AppLocalizations l10n, QuickAddOmission omission) {
    final season = omission.seasonNumber;
    final episode = omission.episodeNumber;
    if (season != null && episode != null) {
      return l10n.debugTitleWithEpisode(
        omission.title,
        l10n.homeEpisodeCode(season, episode),
      );
    }
    final tailSeason = omission.tailSeason;
    final tailEpisode = omission.tailEpisode;
    if (tailSeason != null && tailEpisode != null) {
      return l10n.debugTitleAfterEpisode(
        omission.title,
        l10n.homeEpisodeCode(tailSeason, tailEpisode),
      );
    }
    return omission.title;
  }

  String _omissionDetail(AppLocalizations l10n, QuickAddOmission omission) {
    switch (omission.reason) {
      case QuickAddOmissionReason.optedOut:
        return l10n.debugQuickAddOptedOutDetail;
      case QuickAddOmissionReason.notReleased:
        final airDate = omission.airDate;
        return airDate == null
            ? l10n.debugQuickAddNotReleasedUnknown
            : l10n.debugQuickAddNotReleasedDetail(
                formatMediumDate(l10n, airDate),
              );
      case QuickAddOmissionReason.notPopulated:
        return l10n.debugQuickAddNotPopulatedDetail;
      case QuickAddOmissionReason.noAirDate:
        return l10n.debugQuickAddNoAirDateDetail;
      case QuickAddOmissionReason.noCacheData:
        return l10n.debugQuickAddNoCacheDataDetail;
    }
  }
}
