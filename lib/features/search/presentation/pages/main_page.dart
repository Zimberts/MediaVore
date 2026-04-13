import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
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
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // Default to Discover (SearchPage)
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription? _achievementSubscription;
  final ValueNotifier<int> _discoverSearchTrigger = ValueNotifier<int>(0);

  // Achievement queue logic
  final Queue<Achievement> _achievementQueue = Queue<Achievement>();
  bool _isProcessingQueue = false;
  OverlayEntry? _currentNotification;

  late final List<Widget> _pages = [
    SearchPage(searchTrigger: _discoverSearchTrigger),
    const SavedMediaPage(),
    const SeenHistoryPage(),
    const NotificationCenterPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    // Listen for achievements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AchievementProvider>();
      _achievementSubscription = provider.onAchievementUnlocked.listen((
        achievement,
      ) {
        _queueAchievementNotification(achievement);
      });

      // Check if TMDB API key is missing
      final settings = context.read<SettingsProvider>();
      if (settings.tmdbApiKey.isEmpty) {
        _showApiKeyDialog(context, settings);
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _achievementSubscription?.cancel();
    _currentNotification?.remove();
    _discoverSearchTrigger.dispose();
    super.dispose();
  }

  void _queueAchievementNotification(Achievement achievement) {
    _achievementQueue.add(achievement);
    if (!_isProcessingQueue) {
      _processAchievementQueue();
    }
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
    final mainPageContext = context;

    _currentNotification = OverlayEntry(
      builder: (context) => _AchievementTopBanner(
        achievement: achievement,
        selectedIndex: _selectedIndex,
        mainPageContext: mainPageContext,
        onDismiss: () {
          _currentNotification?.remove();
          _currentNotification = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    Overlay.of(context).insert(_currentNotification!);

    // Auto-dismiss after 4 seconds
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

    // Handle initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (_) {}

    // Handle subsequent links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.path == '/share' ||
        (uri.scheme == 'mediavore' && uri.host == 'share')) {
      final name = uri.queryParameters['name'];
      final itemsStr = uri.queryParameters['items'];

      if (name != null && itemsStr != null) {
        final items = itemsStr.split(',');
        _showImportDialog(name, items);
      }
    }
  }

  void _showImportDialog(String suggestedName, List<String> entries) {
    final controller = TextEditingController(text: suggestedName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to import a list with ${entries.length} items.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'Enter name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<SearchProvider>();
              final navigator = Navigator.of(context);
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
    setState(() {
      _selectedIndex = index;
    });

    // Update provider selected tab if available
    try {
      final provider = context.read<SearchProvider>();
      provider.setSelectedTab(index);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _onItemTapped(0);
          _discoverSearchTrigger.value += 1;
        },
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'My Lists',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Seen'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.tmdbApiKey);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('TMDB API Key Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To use this app, you need a TMDB API key. You can get one for free at themoviedb.org.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter your API key here',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You can set your API key later in Settings (accessible from the My Lists, Seen, or Alerts tabs).',
                      ),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Cancel for now'),
            ),
            FilledButton(
              onPressed: () {
                settings.setTmdbApiKey(controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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

class _AchievementTopBannerState extends State<_AchievementTopBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = kToolbarHeight;

    // Determine current route context
    final route = ModalRoute.of(widget.mainPageContext);
    final isMainPageCurrent = route?.isCurrent ?? true;

    // Check if we are on MediaDetailPage.
    // MediaDetailPage uses Scaffold, so it has its own AppBar.
    // We can check the route name if defined, but usually checking the widget type in the route settings works.
    final bool isMediaDetails =
        route?.settings.name == '/media_details' ||
        (route is MaterialPageRoute &&
            route.builder(context) is MediaDetailPage);

    double topOffset = statusBarHeight + appBarHeight + 8;

    if (isMainPageCurrent) {
      if (widget.selectedIndex == 2) {
        // Seen History search bar
        topOffset += 60;
      } else if (widget.selectedIndex == 3) {
        // Notification Center TabBar
        topOffset += 48;
      }
    } else if (isMediaDetails) {
      // MediaDetailPage has a pinned SliverAppBar that expands.
      // We'll give it a bit more clearance so it doesn't cover the title when pinned.
      topOffset += 8;
    }

    return Positioned(
      top: topOffset,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AchievementsPage(
                    initialAchievementId: widget.achievement.id,
                  ),
                ),
              );
              _handleDismiss();
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < -10) {
                _handleDismiss();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.logicFlow,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.achievement.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: _handleDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
