import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/search_overlay.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static Future<void> syncAllListsToWidget(SearchProvider provider, SettingsProvider settings) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dio = Dio();
      
      // Save available list names for the native dropdown
      await HomeWidget.saveWidgetData('available_lists', jsonEncode(provider.listNames));

      for (final listName in provider.listNames) {
        final previews = provider.getPreviewsForList(listName);
        final List<Map<String, dynamic>> shelfData = [];

        for (final l in previews.take(50)) { // Sync more items to allow native filtering
          String? localPath = '${directory.path}/shelf_${l.id}.jpg';
          if (!File(localPath).existsSync() && l.posterPath != null) {
            try { await dio.download('https://image.tmdb.org/t/p/w92${l.posterPath}', localPath); } catch (_) {}
          }

          // We need releaseDate for the native side to filter unreleased media
          // However, previews don't have releaseDate. We might need to use full items or accept limitations.
          // For now, let's just include it as empty and if we need it, we'd fetch full items.
          shelfData.add({
            'id': l.id.toString(),
            'title': l.title,
            'type': l.type,
            'image_path': localPath,
            'release_date': '', // Placeholder if previews don't have it
          });
        }
        // Save unique data for THIS specific list
        await HomeWidget.saveWidgetData('shelf_data_$listName', jsonEncode(shelfData));
      }
      
      await HomeWidget.updateWidget(androidName: 'ShelfWidgetProvider');
      debugPrint('[Widget] All lists synced to widget storage');
    } catch (e) {
      debugPrint('[Widget] Sync error: $e');
    }
  }

  static Future<void> updateWatchNextWidget(SearchProvider provider) async {
    try {
      final seenItems = provider.seenItems.where((s) => s.type == MediaType.tv).toList();
      if (seenItems.isEmpty) {
        await HomeWidget.saveWidgetData('watch_next_data', '[]');
        await HomeWidget.updateWidget(androidName: 'WatchNextWidgetProvider');
        return;
      }

      final Map<int, DateTime> lastWatchedMap = {};
      for (var item in seenItems) {
        if (!lastWatchedMap.containsKey(item.tmdbId) || item.seenDate.isAfter(lastWatchedMap[item.tmdbId]!)) {
          lastWatchedMap[item.tmdbId] = item.seenDate;
        }
      }

      final sortedIds = lastWatchedMap.keys.toList()..sort((a, b) => lastWatchedMap[b]!.compareTo(lastWatchedMap[a]!));
      final directory = await getApplicationDocumentsDirectory();
      final dio = Dio();
      final List<Map<String, dynamic>> watchNextData = [];

      for (final id in sortedIds.take(10)) {
        final nextEp = await provider.getNextEpisode(id);
        if (nextEp == null) continue;

        try {
          final details = await provider.getMediaDetails(id, MediaType.tv);
          final item = details.item;
          final path = '${directory.path}/watch_next_$id.jpg';
          if (item.posterPath != null && !File(path).existsSync()) {
            await dio.download('https://image.tmdb.org/t/p/w92${item.posterPath}', path);
          }

          watchNextData.add({
            'id': id.toString(),
            'title': item.title,
            'episode_label': 'Next: S${nextEp.seasonNumber.toString().padLeft(2, '0')} E${nextEp.episodeNumber.toString().padLeft(2, '0')}',
            'season': nextEp.seasonNumber,
            'episode': nextEp.episodeNumber,
            'image_path': path,
          });
        } catch (_) { continue; }
      }

      await HomeWidget.saveWidgetData('watch_next_data', jsonEncode(watchNextData));
      await HomeWidget.updateWidget(androidName: 'WatchNextWidgetProvider');
    } catch (e) {
      debugPrint('[Widget] Watch Next Error: $e');
    }
  }

  // Legacy fallback - kept for backward compatibility if called elsewhere
  static Future<void> updateShelfWidget(List<MediaItem> items, {SettingsProvider? settings}) async {
    // This is now handled by syncAllListsToWidget
  }

  static Future<void> updateDiscoveryWidget(List<MediaItem> items) async {
    try {
      if (items.isEmpty) return;
      final validItems = items.where((i) => i.posterPath != null).toList();
      if (validItems.isEmpty) return;
      validItems.shuffle();
      final pool = validItems.take(10).toList();
      final directory = await getApplicationDocumentsDirectory();
      final dio = Dio();
      for (int i = 0; i < pool.length; i++) {
        final item = pool[i];
        final path = '${directory.path}/discovery_poster_$i.jpg';
        await dio.download('https://image.tmdb.org/t/p/w200${item.posterPath}', path);
        final year = item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : '';
        await HomeWidget.saveWidgetData('discovery_title_$i', item.title);
        await HomeWidget.saveWidgetData('discovery_subtitle_$i', item.mediaType == MediaType.tv ? 'TV Show' : 'Movie');
        await HomeWidget.saveWidgetData('discovery_image_$i', path);
        await HomeWidget.saveWidgetData('discovery_id_$i', item.id.toString());
        await HomeWidget.saveWidgetData('discovery_type_$i', item.mediaType.index);
        await HomeWidget.saveWidgetData('discovery_rating_$i', item.voteAverage?.toStringAsFixed(1) ?? '');
        await HomeWidget.saveWidgetData('discovery_year_$i', year);
      }
      await HomeWidget.saveWidgetData('discovery_pool_size', pool.length);
      await HomeWidget.updateWidget(androidName: 'DiscoveryWidgetProvider');
    } catch (e) {
      debugPrint('[Widget] Discovery Error: $e');
    }
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription? _achievementSubscription;

  final Queue<Achievement> _achievementQueue = Queue<Achievement>();
  bool _isProcessingQueue = false;
  OverlayEntry? _currentNotification;

  static const List<Widget> _pages = [
    SearchPage(),
    SavedMediaPage(),
    SeenHistoryPage(),
    NotificationCenterPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      final settings = context.read<SettingsProvider>();
      final achProvider = context.read<AchievementProvider>();
      
      _achievementSubscription = achProvider.onAchievementUnlocked.listen((achievement) {
        _queueAchievementNotification(achievement);
      });
      
      if (provider.items.isNotEmpty) {
        MainPage.updateDiscoveryWidget(provider.items);
      }
      
      MainPage.syncAllListsToWidget(provider, settings);
      MainPage.updateWatchNextWidget(provider);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _achievementSubscription?.cancel();
    _currentNotification?.remove();
    super.dispose();
  }

  void _queueAchievementNotification(Achievement achievement) {
    _achievementQueue.add(achievement);
    if (!_isProcessingQueue) _processAchievementQueue();
  }

  Future<void> _processAchievementQueue() async {
    if (_achievementQueue.isEmpty || !mounted) {
      _isProcessingQueue = false;
      return;
    }
    _isProcessingQueue = true;
    final achievement = _achievementQueue.removeFirst();
    await _showTopNotification(achievement);
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _processAchievementQueue();
    }
  }

  Future<void> _showTopNotification(Achievement achievement) async {
    if (!mounted) return;
    final completer = Completer<void>();
    _currentNotification = OverlayEntry(
      builder: (context) => _AchievementTopBanner(
        achievement: achievement,
        selectedIndex: _selectedIndex,
        mainPageContext: context,
        onDismiss: () {
          _currentNotification?.remove();
          _currentNotification = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    Overlay.of(context).insert(_currentNotification!);
    Future.delayed(const Duration(seconds: 4), () {
      if (_currentNotification != null && !completer.isCompleted) {
        _currentNotification?.remove();
        _currentNotification = null;
        completer.complete();
      }
    });
    return completer.future;
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('[MainPage] Initial link: $initialLink');
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('[MainPage] Error: $e');
    }
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('[MainPage] Stream link: $uri');
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    final scheme = uri.scheme;
    final host = uri.host.toLowerCase();
    final params = uri.queryParameters;

    debugPrint('[MainPage] Handling Link: $scheme://$host with params $params');

    if (uri.path == '/share' || (scheme == 'mediavore' && host == 'share')) {
      final name = params['name'];
      final itemsStr = params['items'];
      if (name != null && itemsStr != null) _showImportDialog(name, itemsStr.split(','));
      return;
    } 
    
    if (scheme == 'mediavore') {
      switch (host) {
        case 'search':
          _openSearch();
          break;
        case 'scan':
          _openSearch(startWithScan: true);
          break;
        case 'details':
          final id = int.tryParse(params['id'] ?? '');
          final type = params['type'] == 'tv' ? MediaType.tv : MediaType.movie;
          if (id != null) _openDetails(id, type);
          break;
        case 'markseen':
          final id = int.tryParse(params['id'] ?? '');
          final s = int.tryParse(params['s'] ?? '');
          final e = int.tryParse(params['e'] ?? '');
          final t = params['t'];
          if (id != null && s != null && e != null) {
            _markAsSeen(id, s, e, title: t != null ? Uri.decodeComponent(t) : null);
          }
          break;
        case 'main':
          setState(() => _selectedIndex = 0);
          break;
        case 'settings':
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
          break;
      }
    }
  }

  Future<void> _markAsSeen(int id, int season, int episode, {String? title}) async {
    debugPrint('[MainPage] EXEC MarkSeen: $id S$season E$episode');
    final provider = context.read<SearchProvider>();
    
    try {
      String finalTitle = title ?? 'TV Show';
      String? posterPath;

      if (title == null || title == 'Unknown' || title == '...') {
        try {
          final details = await provider.getMediaDetails(id, MediaType.tv);
          finalTitle = details.item.title;
          posterPath = details.item.posterPath;
        } catch (e) {
          debugPrint('[MainPage] Fetch failed: $e');
        }
      }
      
      final seen = SeenItem(
        tmdbId: id,
        type: MediaType.tv,
        title: finalTitle,
        posterPath: posterPath,
        seenDate: DateTime.now(),
        seasonNumber: season,
        episodeNumber: episode,
      );
      
      await provider.markAsSeen(seen);
      await MainPage.updateWatchNextWidget(provider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked $finalTitle S${season}E${episode} as seen!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MainPage] MarkSeen FAILED: $e');
    }
  }

  void _openDetails(int id, MediaType type) {
    final item = MediaItem(id: id, title: 'Loading...', overview: '', posterPath: null, releaseDate: '', mediaType: type);
    MediaDetailPage.show(context, item);
  }

  void _openSearch({bool startWithScan = false}) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => SearchOverlay(initialScan: startWithScan),
      fullscreenDialog: true,
    ));
  }

  void _showImportDialog(String suggestedName, List<String> entries) {
    final controller = TextEditingController(text: suggestedName);
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import list with ${entries.length} items?'),
            const SizedBox(height: 16),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'List Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => navigator.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final provider = context.read<SearchProvider>();
              await provider.importList(controller.text, entries);
              if (mounted) {
                navigator.pop();
                setState(() => _selectedIndex = 1);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    try {
      context.read<SearchProvider>().setSelectedTab(index);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSearch(),
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'My Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Seen'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _AchievementTopBanner extends StatefulWidget {
  final Achievement achievement;
  final int selectedIndex;
  final BuildContext mainPageContext;
  final VoidCallback onDismiss;

  const _AchievementTopBanner({
    required this.achievement,
    required this.selectedIndex,
    required this.mainPageContext,
    required this.onDismiss,
  });

  @override
  State<_AchievementTopBanner> createState() => _AchievementTopBannerState();
}

class _AchievementTopBannerState extends State<_AchievementTopBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AchievementsPage(initialAchievementId: widget.achievement.id)));
              widget.onDismiss();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: colors.logicFlow, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(child: Text(widget.achievement.title, style: const TextStyle(color: Colors.white))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: widget.onDismiss),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
