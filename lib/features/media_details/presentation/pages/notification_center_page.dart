import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/notification_center_filter.dart';
import 'package:mediavore/core/utils/release_sort.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => NotificationCenterPageState();
}

class NotificationCenterPageState extends State<NotificationCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_QuickAddTabState> _quickAddKey =
      GlobalKey<_QuickAddTabState>();
  final GlobalKey<_ReleasesTabState> _releasesKey =
      GlobalKey<_ReleasesTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final provider = context.read<SearchProvider>();
    final debug = context.read<SettingsProvider>().notificationCenterDebug;
    await provider.refreshNotifiedItems(); // Refresh dates from network
    await provider.loadNotifiedItems();
    await provider.loadAllSeenStatus();
    await provider.refreshQuickAddItems(); // Backfill missing runtimes
    await provider.loadQuickAddItems();
    if (debug) {
      await provider.loadQuickAddOmissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
            tooltip: 'Force Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Releases'),
            Tab(text: 'Quick Add'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _ReleasesTab(key: _releasesKey, onRefresh: refresh),
              _QuickAddTab(key: _quickAddKey, onRefresh: refresh),
            ],
          ),
          if (context.watch<SearchProvider>().isNotifiedRefreshing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Syncing releases...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReleasesTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const _ReleasesTab({super.key, required this.onRefresh});

  @override
  State<_ReleasesTab> createState() => _ReleasesTabState();
}

class _ReleasesTabState extends State<_ReleasesTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();

        // Split notified items into the ones shown and the ones hidden from the
        // list, keeping the reason each hidden item was omitted (used in debug).
        final filterResult = filterReleases(
          items: provider.notifiedItems,
          seenItems: provider.seenItems,
          now: now,
        );

        final releases = sortReleases(filterResult.visible);
        final debug = context.watch<SettingsProvider>().notificationCenterDebug;
        final debugChildren = debug
            ? _buildReleaseDebugSections(filterResult.omitted)
            : const <Widget>[];

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: (releases.isEmpty && debugChildren.isEmpty)
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No upcoming or recent releases.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: releases.length + debugChildren.length,
                  itemBuilder: (context, index) {
                    if (index >= releases.length) {
                      return debugChildren[index - releases.length];
                    }
                    final item = releases[index];
                    final isReleased = item.releaseDate != null
                        ? !item.releaseDate!.isAfter(now)
                        : false;

                    String title = item.title;
                    if (item.type == MediaType.tv &&
                        item.seasonNumber != null) {
                      title +=
                          ' (S${item.seasonNumber} E${item.episodeNumber})';
                    }

                    final runtimeText = Formatters.formatRuntime(item.runtime);
                    final subtitleText =
                        (item.releaseDate != null
                            ? '${isReleased ? "Released" : "Releases"}: ${DateFormat.yMMMd().format(item.releaseDate!)}'
                            : releaseSubtitleForItem(item)) +
                        (runtimeText.isNotEmpty ? ' · $runtimeText' : '');
                    final subtitleColor = item.releaseDate != null
                        ? (isReleased ? Colors.green : Colors.orange)
                        : Colors.grey;

                    return ListTile(
                      leading: item.posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w92${item.posterPath}',
                            )
                          : const Icon(Icons.movie),
                      title: Text(title),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(color: subtitleColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isReleased)
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.green,
                              ),
                              tooltip: 'Mark as seen',
                              onPressed: () async {
                                if (item.type == MediaType.movie) {
                                  await provider.markAsSeen(
                                    SeenItem(
                                      tmdbId: item.tmdbId,
                                      type: item.type,
                                      title: item.title,
                                      posterPath: item.posterPath,
                                      seenDate: DateTime.now(),
                                    ),
                                  );
                                } else {
                                  // Mark the SPECIFIC notified episode as seen
                                  await provider.markAsSeen(
                                    SeenItem(
                                      tmdbId: item.tmdbId,
                                      type: item.type,
                                      title: item.title,
                                      posterPath: item.posterPath,
                                      seenDate: DateTime.now(),
                                      seasonNumber: item.seasonNumber,
                                      episodeNumber: item.episodeNumber,
                                    ),
                                  );
                                }

                                // Refresh to find the NEXT episode milestone
                                await provider.getMediaDetails(
                                  item.tmdbId,
                                  item.type,
                                );
                                await provider.loadNotifiedItems();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Marked ${item.title} as seen',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.notifications_off_outlined),
                            onPressed: () {
                              final mediaItem = MediaItem(
                                id: item.tmdbId,
                                title: item.title,
                                overview: '',
                                releaseDate:
                                    item.releaseDate?.toIso8601String() ?? '',
                                mediaType: item.type,
                              );
                              provider.toggleNotification(mediaItem);
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        final details = await provider.getMediaDetails(
                          item.tmdbId,
                          item.type,
                        );
                        if (context.mounted) {
                          await MediaDetailPage.show(context, details.item);
                        }
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _QuickAddTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const _QuickAddTab({super.key, required this.onRefresh});

  @override
  State<_QuickAddTab> createState() => _QuickAddTabState();
}

class _QuickAddTabState extends State<_QuickAddTab> {
  bool _debugLoadRequested = false;

  @override
  Widget build(BuildContext context) {
    final debug = context.watch<SettingsProvider>().notificationCenterDebug;

    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final items = provider.quickAddItems;

        // Lazily compute the diagnostics once when debug is enabled.
        if (debug && !_debugLoadRequested) {
          _debugLoadRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<SearchProvider>().loadQuickAddOmissions();
            }
          });
        }

        final debugChildren = debug
            ? _buildQuickAddDebugSections(
                context,
                provider.quickAddOmissions,
                provider.isQuickAddOmissionsLoading,
              )
            : const <Widget>[];

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: (items.isEmpty && debugChildren.isEmpty)
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No next episodes to track.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length + debugChildren.length,
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return debugChildren[index - items.length];
                    }
                    final qa = items[index];
                    final tmdbId = qa.tmdbId;
                    final title = qa.title ?? 'Unknown';
                    final posterPath = qa.posterPath;

                    String subtitle = '';
                    if (qa.seasonNumber != null && qa.episodeNumber != null) {
                      subtitle =
                          'Next: Season ${qa.seasonNumber}, Episode ${qa.episodeNumber}';
                    }
                    final runtimeText = Formatters.formatRuntime(qa.runtime);
                    if (runtimeText.isNotEmpty) {
                      subtitle = subtitle.isEmpty
                          ? runtimeText
                          : '$subtitle · $runtimeText';
                    }

                    final dismissKey =
                        '${qa.tmdbId}-${qa.seasonNumber ?? 0}-${qa.episodeNumber ?? 0}-${qa.insertedAt.millisecondsSinceEpoch}';

                    return Dismissible(
                      key: ValueKey(dismissKey),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.block, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return true; // allow swipe; perform opt-out in onDismissed to show Undo
                      },
                      onDismissed: (direction) async {
                        try {
                          await provider.optOutSeries(
                            tmdbId,
                            seasonNumber: qa.seasonNumber,
                            episodeNumber: qa.episodeNumber,
                          );
                          await provider.loadQuickAddItems();
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            // Remove any existing SnackBar immediately so the new one appears
                            messenger.removeCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Streak opted out of Quick Add',
                                ),
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    try {
                                      await provider.clearOptOutSeries(
                                        tmdbId,
                                        seasonNumber: qa.seasonNumber,
                                        episodeNumber: qa.episodeNumber,
                                      );
                                      // Restore the exact dismissed quick-add entry directly
                                      await provider.addQuickAddItem(qa);
                                    } catch (e) {
                                      debugPrint('[NotificationCenter] undo streak opt-out failed: $e');
                                    }
                                  },
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('[NotificationCenter] streak opt-out failed: $e');
                        }
                      },
                      child: ListTile(
                        leading: posterPath != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w92$posterPath',
                              )
                            : const Icon(Icons.tv),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            await provider.markAsSeen(
                              SeenItem(
                                tmdbId: qa.tmdbId,
                                type: qa.type,
                                title: qa.title ?? '',
                                posterPath: qa.posterPath,
                                seenDate: DateTime.now(),
                                seasonNumber: qa.seasonNumber,
                                episodeNumber: qa.episodeNumber,
                              ),
                            );
                            await provider.loadQuickAddItems();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Marked ${qa.title ?? 'episode'} as seen',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          final details = await provider.getMediaDetails(
                            qa.tmdbId,
                            qa.type,
                          );
                          if (context.mounted) {
                            await MediaDetailPage.show(context, details.item);
                          }
                        },
                        // Long-press removed; swipe-to-dismiss handles opt-out.
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Builds the debug-only sections appended below the releases list, grouping
/// omitted items by the reason they were hidden.
List<Widget> _buildReleaseDebugSections(List<ReleaseOmission> omissions) {
  final widgets = <Widget>[
    const _DebugSectionHeader(
      title: 'Debug — hidden releases',
      subtitle: 'These items exist in the database but are omitted above.',
    ),
  ];

  if (omissions.isEmpty) {
    widgets.add(
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text('Nothing omitted.'),
      ),
    );
    return widgets;
  }

  void addGroup(String title, ReleaseOmissionReason reason) {
    final group = omissions.where((o) => o.reason == reason).toList();
    if (group.isEmpty) return;
    widgets.add(_DebugGroupLabel(title: title, count: group.length));
    for (final omission in group) {
      widgets.add(
        _DebugOmittedTile(
          title: _releaseDebugTitle(omission.item),
          subtitle: _releaseOmissionDetail(omission),
        ),
      );
    }
  }

  addGroup('Already seen', ReleaseOmissionReason.alreadySeen);
  addGroup(
    'Aired more than 30 days ago',
    ReleaseOmissionReason.olderThan30Days,
  );

  return widgets;
}

String _releaseDebugTitle(NotifiedItem item) {
  if (item.type == MediaType.tv && item.seasonNumber != null) {
    return '${item.title} (S${item.seasonNumber} E${item.episodeNumber})';
  }
  return item.title;
}

String _releaseOmissionDetail(ReleaseOmission omission) {
  final dateText = omission.item.releaseDate != null
      ? DateFormat.yMMMd().format(omission.item.releaseDate!)
      : 'no date stored';
  switch (omission.reason) {
    case ReleaseOmissionReason.alreadySeen:
      return 'Already marked as seen';
    case ReleaseOmissionReason.olderThan30Days:
      return 'Stored air date: $dateText (older than 30 days)';
  }
}

/// Header shown once at the top of a debug block of omitted items.
class _DebugSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const _DebugSectionHeader({required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report_outlined, size: 18, color: colors.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(color: colors.tertiary),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// Small label introducing a group of omitted items (e.g. "Already seen (2)").
class _DebugGroupLabel extends StatelessWidget {
  final String title;
  final int count;

  const _DebugGroupLabel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        '$title ($count)',
        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// A single omitted item row in a debug section.
class _DebugOmittedTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DebugOmittedTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.visibility_off_outlined, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

/// Builds the debug-only sections appended below the Quick Add list, grouping
/// missing expected episodes by the reason they are absent.
List<Widget> _buildQuickAddDebugSections(
  BuildContext context,
  List<QuickAddOmission> omissions,
  bool loading,
) {
  final provider = context.read<SearchProvider>();

  final widgets = <Widget>[
    _DebugSectionHeader(
      title: 'Debug — missing episodes',
      subtitle: 'Expected next episodes that are not shown above.',
      action: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Recompute'),
              onPressed: () => provider.loadQuickAddOmissions(allowFetch: true),
            ),
    ),
  ];

  if (!loading && omissions.isEmpty) {
    widgets.add(
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text('Nothing omitted.'),
      ),
    );
    return widgets;
  }

  void addGroup(String title, QuickAddOmissionReason reason) {
    final group = omissions.where((o) => o.reason == reason).toList();
    if (group.isEmpty) return;
    widgets.add(_DebugGroupLabel(title: title, count: group.length));
    for (final omission in group) {
      widgets.add(
        _DebugOmittedTile(
          title: _quickAddDebugTitle(omission),
          subtitle: _quickAddOmissionDetail(omission),
        ),
      );
    }
  }

  addGroup('Opted out', QuickAddOmissionReason.optedOut);
  addGroup('Not released yet', QuickAddOmissionReason.notReleased);
  addGroup('Not added to Quick Add', QuickAddOmissionReason.notPopulated);
  addGroup('No air date', QuickAddOmissionReason.noAirDate);
  addGroup('Season data not cached', QuickAddOmissionReason.noCacheData);

  return widgets;
}

String _quickAddDebugTitle(QuickAddOmission omission) {
  if (omission.seasonNumber != null) {
    return '${omission.title} (S${omission.seasonNumber} E${omission.episodeNumber})';
  }
  if (omission.tailSeason != null) {
    return '${omission.title} (after S${omission.tailSeason} E${omission.tailEpisode})';
  }
  return omission.title;
}

String _quickAddOmissionDetail(QuickAddOmission omission) {
  switch (omission.reason) {
    case QuickAddOmissionReason.optedOut:
      return 'Opted out for S${omission.seasonNumber} E${omission.episodeNumber} (swipe dismiss)';
    case QuickAddOmissionReason.notReleased:
      final dateText = omission.airDate != null
          ? DateFormat.yMMMd().format(omission.airDate!)
          : 'unknown';
      return 'Not aired yet — airs $dateText';
    case QuickAddOmissionReason.notPopulated:
      return 'Aired episode missing from Quick Add (try Recompute)';
    case QuickAddOmissionReason.noAirDate:
      return 'Episode has no known air date';
    case QuickAddOmissionReason.noCacheData:
      return 'Season data not cached — tap Recompute to fetch';
  }
}
