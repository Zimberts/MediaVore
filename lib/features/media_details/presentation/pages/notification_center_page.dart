import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:provider/provider.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => NotificationCenterPageState();
}

class NotificationCenterPageState extends State<NotificationCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_QuickAddTabState> _quickAddKey = GlobalKey<_QuickAddTabState>();
  final GlobalKey<_ReleasesTabState> _releasesKey = GlobalKey<_ReleasesTabState>();

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
    _quickAddKey.currentState?.loadNextEpisodes();
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
                        Text('Syncing releases...', style: TextStyle(fontWeight: FontWeight.bold)),
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
        final startOfDay = DateTime(now.year, now.month, now.day);
        final oneMonthAgo = startOfDay.subtract(const Duration(days: 30));
        
        debugPrint('--- Releases Tab Filtering Log ---');
        debugPrint('Total notified items in provider: ${provider.notifiedItems.length}');

        final releases = provider.notifiedItems.where((item) {
          if (item.releaseDate == null) {
            debugPrint('Item "${item.title}" excluded: releaseDate is null');
            return false;
          }
          
          final releaseDate = item.releaseDate!;
          final releaseDay = DateTime(releaseDate.year, releaseDate.month, releaseDate.day);

          // Filtering by "Seen" status
          if (item.type == MediaType.movie) {
            final seenCount = provider.seenItems.where((s) => s.tmdbId == item.tmdbId).length;
            if (seenCount > 0) {
              debugPrint('Movie "${item.title}" excluded: already seen ($seenCount times)');
              return false;
            }
          }
          
          if (item.type == MediaType.tv) {
            // FIX: Use season and episode number for precise filtering
            if (item.seasonNumber != null && item.episodeNumber != null) {
              final isEpSeen = provider.seenItems.any((s) => 
                s.tmdbId == item.tmdbId && 
                s.type == MediaType.tv &&
                s.seasonNumber == item.seasonNumber && 
                s.episodeNumber == item.episodeNumber
              );
              if (isEpSeen) {
                debugPrint('Series "${item.title}" excluded: specific episode S${item.seasonNumber} E${item.episodeNumber} already seen');
                return false;
              }
            } else {
              // Fallback to date-based logic ONLY if episode info is missing
              final alreadySeenRecent = provider.seenItems.any((s) => 
                s.tmdbId == item.tmdbId && 
                s.type == MediaType.tv &&
                (s.seenDate.isAfter(releaseDay) || 
                 DateUtils.isSameDay(s.seenDate, releaseDay))
              );
              if (alreadySeenRecent) {
                debugPrint('Series "${item.title}" excluded: marked as seen on/after release date (date-fallback)');
                return false;
              }
            }
          }

          // Check if it's within our window
          final isRecent = releaseDay.isAfter(oneMonthAgo) || DateUtils.isSameDay(releaseDay, startOfDay);
          if (!isRecent) {
            debugPrint('Item "${item.title}" excluded: release day ${DateFormat.yMd().format(releaseDay)} is outside window (after ${DateFormat.yMd().format(oneMonthAgo)})');
          } else {
            debugPrint('Item "${item.title}" INCLUDED: release day ${DateFormat.yMd().format(releaseDay)}');
          }

          return isRecent;
        }).toList();

        releases.sort((a, b) => a.releaseDate!.compareTo(b.releaseDate!));

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
                    final isReleased = !item.releaseDate!.isAfter(now);
                    
                    String title = item.title;
                    if (item.type == MediaType.tv && item.seasonNumber != null) {
                      title += ' (S${item.seasonNumber} E${item.episodeNumber})';
                    }

                    return ListTile(
                      leading: item.posterPath != null 
                        ? Image.network('https://image.tmdb.org/t/p/w92${item.posterPath}')
                        : const Icon(Icons.movie),
                      title: Text(title),
                      subtitle: Text(
                        '${isReleased ? "Released" : "Releases"}: ${DateFormat.yMMMd().format(item.releaseDate!)}',
                        style: TextStyle(color: isReleased ? Colors.green : Colors.orange),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isReleased)
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.green),
                              tooltip: 'Mark as seen',
                              onPressed: () async {
                                if (item.type == MediaType.movie) {
                                  await provider.markAsSeen(SeenItem(
                                    tmdbId: item.tmdbId,
                                    type: item.type,
                                    title: item.title,
                                    posterPath: item.posterPath,
                                    seenDate: DateTime.now(),
                                  ));
                                } else {
                                  // Mark the SPECIFIC notified episode as seen
                                  await provider.markAsSeen(SeenItem(
                                    tmdbId: item.tmdbId,
                                    type: item.type,
                                    title: item.title,
                                    posterPath: item.posterPath,
                                    seenDate: DateTime.now(),
                                    seasonNumber: item.seasonNumber,
                                    episodeNumber: item.episodeNumber,
                                  ));
                                }
                                
                                // Refresh to find the NEXT episode milestone
                                await provider.getMediaDetails(item.tmdbId, item.type);
                                await provider.loadNotifiedItems();
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Marked ${item.title} as seen')),
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
                                releaseDate: item.releaseDate?.toIso8601String() ?? '',
                                mediaType: item.type,
                              );
                              provider.toggleNotification(mediaItem);
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        final details = await provider.getMediaDetails(item.tmdbId, item.type);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MediaDetailPage(item: details.item)),
                          );
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
  final Map<int, ({int seasonNumber, int episodeNumber})?> _nextEpisodes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNextEpisodes();
  }

  Future<void> loadNextEpisodes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final provider = context.read<SearchProvider>();
    final seenSeries = provider.seenItems
        .where((s) => s.type == MediaType.tv)
        .map((s) => s.tmdbId)
        .toSet();

    for (final id in seenSeries) {
      final next = await provider.getNextEpisode(id);
      _nextEpisodes[id] = next;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final seriesToDisplay = _nextEpisodes.entries
            .where((e) => e.value != null)
            .toList();

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: seriesToDisplay.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No next episodes to track.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: seriesToDisplay.length,
                  itemBuilder: (context, index) {
                    final entry = seriesToDisplay[index];
                    final tmdbId = entry.key;
                    final nextEp = entry.value!;
                    
                    final title = provider.seenItems.firstWhere((s) => s.tmdbId == tmdbId).title;
                    final posterPath = provider.seenItems.firstWhere((s) => s.tmdbId == tmdbId).posterPath;

                    return ListTile(
                      leading: posterPath != null 
                        ? Image.network('https://image.tmdb.org/t/p/w92$posterPath')
                        : const Icon(Icons.tv),
                      title: Text(title),
                      subtitle: Text('Next: Season ${nextEp.seasonNumber}, Episode ${nextEp.episodeNumber}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        onPressed: () async {
                          final seenItem = provider.seenItems.firstWhere((s) => s.tmdbId == tmdbId);
                          await provider.markAsSeen(seenItem.copyWith(
                            seenDate: DateTime.now(),
                            seasonNumber: nextEp.seasonNumber,
                            episodeNumber: nextEp.episodeNumber,
                          ));
                          loadNextEpisodes();
                        },
                      ),
                      onTap: () async {
                         final details = await provider.getMediaDetails(tmdbId, MediaType.tv);
                         if (context.mounted) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => MediaDetailPage(item: details.item)),
                           );
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
