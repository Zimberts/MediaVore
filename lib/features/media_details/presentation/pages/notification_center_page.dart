import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/utils/release_sort.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
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
    await provider.refreshNotifiedItems(); // Refresh dates from network
    await provider.loadNotifiedItems();
    await provider.loadAllSeenStatus();
    await provider.loadQuickAddItems();
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

        // Build the releases list: include all notified items but filter out things
        // the user already marked as seen. We'll then sort by concrete date first
        // and append unplanned items grouped by type.
        final filtered = <NotifiedItem>[];
        for (final item in provider.notifiedItems) {
          // Filtering by "Seen" status
          bool isSeen = false;
          if (item.type == MediaType.movie) {
            final seenCount = provider.seenItems
                .where((s) => s.tmdbId == item.tmdbId)
                .length;
            if (seenCount > 0) isSeen = true;
          } else if (item.type == MediaType.tv) {
            if (item.seasonNumber != null && item.episodeNumber != null) {
              final isEpSeen = provider.seenItems.any(
                (s) =>
                    s.tmdbId == item.tmdbId &&
                    s.type == MediaType.tv &&
                    s.seasonNumber == item.seasonNumber &&
                    s.episodeNumber == item.episodeNumber,
              );
              if (isEpSeen) isSeen = true;
            } else if (item.releaseDate != null) {
              // Fallback to date-based logic ONLY if episode info is missing
              final releaseDay = DateTime(
                item.releaseDate!.year,
                item.releaseDate!.month,
                item.releaseDate!.day,
              );
              final alreadySeenRecent = provider.seenItems.any(
                (s) =>
                    s.tmdbId == item.tmdbId &&
                    s.type == MediaType.tv &&
                    (s.seenDate.isAfter(releaseDay) ||
                        DateUtils.isSameDay(s.seenDate, releaseDay)),
              );
              if (alreadySeenRecent) isSeen = true;
            }
          }

          if (!isSeen) {
            // Skip old TV releases (30+ days) to reduce clutter, but keep them notified
            if (item.type == MediaType.tv && item.releaseDate != null) {
              final thirtyDaysAgo = now.subtract(const Duration(days: 30));
              if (item.releaseDate!.isBefore(thirtyDaysAgo)) {
                continue; // Hide old episode, user can catch up
              }
            }
            filtered.add(item);
          }
        }

        final releases = sortReleases(filtered);

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: releases.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No upcoming or recent releases.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: releases.length,
                  itemBuilder: (context, index) {
                    final item = releases[index];
                    final isReleased = item.releaseDate != null
                        ? !item.releaseDate!.isAfter(now)
                        : false;

                    String title = item.title;
                    if (item.type == MediaType.tv && item.seasonNumber != null) {
                      title += ' (S${item.seasonNumber} E${item.episodeNumber})';
                    }

                    final subtitleText = item.releaseDate != null
                        ? '${isReleased ? "Released" : "Releases"}: ${DateFormat.yMMMd().format(item.releaseDate!)}'
                        : releaseSubtitleForItem(item);
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
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final items = provider.quickAddItems;

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No next episodes to track.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final qa = items[index];
                    final tmdbId = qa.tmdbId;
                    final title = qa.title ?? 'Unknown';
                    final posterPath = qa.posterPath;

                    String subtitle = '';
                    if (qa.seasonNumber != null && qa.episodeNumber != null) {
                      subtitle =
                          'Next: Season ${qa.seasonNumber}, Episode ${qa.episodeNumber}';
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
                                content: const Text('Streak opted out of Quick Add'),
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
                                    } catch (_) {}
                                  },
                                ),
                              ),
                            );
                          }
                        } catch (_) {}
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
                                SnackBar(content: Text('Marked ${qa.title ?? 'episode'} as seen')),
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
