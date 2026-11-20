import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/notification_center_filter.dart';
import 'package:mediavore/core/utils/release_groups.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/home/presentation/providers/home_session_provider.dart';
import 'package:mediavore/features/home/presentation/widgets/debug_omissions_section.dart';
import 'package:mediavore/features/home/presentation/widgets/upcoming_rows_card.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// TMDB type of a kind shown in "Upcoming" (no release source for books).
MediaType? upcomingTypeOf(MediaKind? kind) => switch (kind) {
  MediaKind.movie => MediaType.movie,
  MediaKind.series => MediaType.tv,
  MediaKind.book || null => null,
};

/// Kinds offered as filter chips of "Upcoming": the kinds present, when
/// there are at least two.
List<MediaKind> upcomingFilterKinds(Iterable<NotifiedItem> items) =>
    progressFilterKinds(
      items.map((item) => MediaKind.fromMediaType(item.type)),
    );

/// Every followed release, opened from "See all" on Home: already released
/// and not seen, then month by month, then the ones without a date and,
/// with the notification debug setting, the hidden ones grouped by reason.
///
/// The kind filter lives in [HomeSessionProvider], shared with Home.
class UpcomingPage extends StatelessWidget {
  const UpcomingPage({super.key, this.clock = DateTime.now});

  /// Current time; overridable for tests.
  final DateTime Function() clock;

  static Future<void> show(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const UpcomingPage()));

  static const double _gutter = 16;

  Future<void> _refresh(BuildContext context) async {
    final notificationProvider = context.read<NotificationProvider?>();
    final isRefreshing = notificationProvider != null
        ? notificationProvider.isNotifiedRefreshing
        : context.read<SearchProvider>().isNotifiedRefreshing;
    if (isRefreshing) return;
    try {
      if (notificationProvider != null) {
        await notificationProvider.refreshNotifiedItems();
      } else {
        await context.read<SearchProvider>().refreshNotifiedItems();
      }
      if (context.mounted) {
        await context.read<SearchProvider>().loadAllSeenStatus();
      }
    } catch (e) {
      debugPrint('[UpcomingPage] refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final notificationProvider = context.watch<NotificationProvider?>();
    final searchProvider = context.watch<SearchProvider>();
    final notifiedItems = notificationProvider != null
        ? notificationProvider.notifiedItems
        : searchProvider.notifiedItems;
    final isRefreshing = notificationProvider != null
        ? notificationProvider.isNotifiedRefreshing
        : searchProvider.isNotifiedRefreshing;
    final session = context.watch<HomeSessionProvider>();
    final debug = context.select<SettingsProvider, bool>(
      (settings) => settings.notificationCenterDebug,
    );
    final now = clock();

    final filtered = filterReleases(
      items: notifiedItems,
      seenItems: searchProvider.seenItems,
      now: now,
    );
    final all = groupReleases(filtered.visible, now: now);
    final filterKinds = upcomingFilterKinds(filtered.visible);
    final kind = filterKinds.contains(session.upcomingKind)
        ? session.upcomingKind
        : null;
    final groups = kind == null
        ? all
        : groupReleases(filtered.visible, now: now, type: upcomingTypeOf(kind));
    final released = groups.of(ReleasePeriod.released);
    final months = groups.upcomingByMonth;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(l10n.upcomingTitle(all.datedCount))),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(_gutter, 4, _gutter, 96),
          children: [
            if (filterKinds.isNotEmpty)
              FilterChipRow(
                key: const Key('upcoming_filters'),
                chips: [
                  AppFilterChip(
                    label: l10n.discoverTypeAll,
                    selected: kind == null,
                    onTap: () => session.setUpcomingKind(null),
                  ),
                  for (final filterKind in filterKinds)
                    AppFilterChip(
                      label: switch (filterKind) {
                        MediaKind.movie => l10n.discoverTypeFilms,
                        MediaKind.series => l10n.discoverTypeSeries,
                        MediaKind.book => l10n.discoverTypeBooks,
                      },
                      selected: kind == filterKind,
                      onTap: () => session.setUpcomingKind(filterKind),
                    ),
                ],
              ),
            if (groups.datedCount == 0)
              Padding(
                key: const Key('upcoming_empty'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.upcomingNothingPlanned,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.text2),
                ),
              ),
            if (released.isNotEmpty) ...[
              SectionHeader(
                title: l10n.upcomingGroupCount(
                  l10n.upcomingGroupReleased,
                  released.length,
                ),
              ),
              UpcomingRowsCard(
                key: const Key('upcoming_released'),
                items: released,
                now: now,
              ),
              const SizedBox(height: 12),
            ],
            for (final month in months) ...[
              SectionHeader(
                title: l10n.upcomingGroupCount(
                  formatMonthYear(l10n, month.month),
                  month.items.length,
                ),
              ),
              UpcomingRowsCard(
                key: ValueKey(
                  'upcoming_month_${month.month.year}_${month.month.month}',
                ),
                items: month.items,
                now: now,
              ),
              const SizedBox(height: 12),
            ],
            if (groups.undated.isNotEmpty) ...[
              SectionHeader(
                title: l10n.upcomingUndatedSection(groups.undated.length),
              ),
              UpcomingRowsCard(
                key: const Key('upcoming_undated'),
                items: groups.undated,
                now: now,
              ),
            ],
            if (debug) ...[
              const SizedBox(height: 20),
              HiddenReleasesDebugSection(
                omissions: filtered.omitted,
                onRecompute: () => _refresh(context),
                loading: isRefreshing,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Debug block of "Upcoming": the followed releases hidden from the list,
/// grouped by reason.
class HiddenReleasesDebugSection extends StatelessWidget {
  const HiddenReleasesDebugSection({
    super.key,
    required this.omissions,
    required this.onRecompute,
    this.loading = false,
  });

  final List<ReleaseOmission> omissions;

  /// Refreshes the releases, then the diagnostic.
  final VoidCallback onRecompute;
  final bool loading;

  /// Days after which an aired episode is hidden (see `filterReleases`).
  static const int staleDays = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    String title(NotifiedItem item) {
      final season = item.seasonNumber;
      final episode = item.episodeNumber;
      return item.type == MediaType.tv && season != null && episode != null
          ? l10n.debugTitleWithEpisode(
              item.title,
              l10n.homeEpisodeCode(season, episode),
            )
          : item.title;
    }

    String detail(ReleaseOmission omission) {
      switch (omission.reason) {
        case ReleaseOmissionReason.alreadySeen:
          return l10n.debugReleaseAlreadySeenDetail;
        case ReleaseOmissionReason.olderThan30Days:
          final date = omission.item.releaseDate;
          return date == null
              ? l10n.debugReleaseNoDate
              : l10n.debugReleaseTooOldDetail(formatMediumDate(l10n, date));
      }
    }

    DebugOmissionGroup group(String reason, ReleaseOmissionReason value) =>
        DebugOmissionGroup(
          reason: reason,
          entries: [
            for (final omission in omissions)
              if (omission.reason == value)
                DebugOmissionEntry(
                  title: title(omission.item),
                  detail: detail(omission),
                ),
          ],
        );

    return DebugOmissionsSection(
      title: l10n.debugHiddenReleasesTitle,
      subtitle: l10n.debugHiddenReleasesSubtitle,
      loading: loading,
      actionLabel: l10n.debugRecompute,
      onAction: onRecompute,
      groups: [
        group(l10n.debugReleaseAlreadySeen, ReleaseOmissionReason.alreadySeen),
        group(
          l10n.debugReleaseTooOld(staleDays),
          ReleaseOmissionReason.olderThan30Days,
        ),
      ],
    );
  }
}
