import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:mediavore/core/database/app_database.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/navigation/app_tab_bar.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/home/presentation/pages/home_page.dart';
import 'package:mediavore/features/library/presentation/pages/library_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mediavore/features/profile/presentation/pages/profile_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/incoming_list_sheet.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mediavore/features/together/presentation/pages/together_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.tabs});

  /// Tabs of the shell, in order; [AppTab.visibleTabs] by default.
  final List<AppTab>? tabs;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<void>? _achievementSubscription;

  // Achievement queue logic
  final Queue<Achievement> _achievementQueue = Queue<Achievement>();
  bool _isProcessingQueue = false;
  OverlayEntry? _currentNotification;

  /// Completes when the banner on screen goes away; the queue waits on it.
  Completer<void>? _notificationDone;

  bool _isOnboardingActive = false;
  Uri? _pendingDeepLink;

  List<AppTab> get _tabs => widget.tabs ?? AppTab.visibleTabs;

  /// Provisional content of each tab; every epic then replaces its own.
  Widget _pageFor(AppTab tab) => switch (tab) {
    AppTab.home => HomePage(showTogetherLink: _tabs.contains(AppTab.together)),
    AppTab.discover => const SearchPage(),
    AppTab.library => const LibraryPage(),
    AppTab.together => const TogetherPage(),
    AppTab.me => const ProfilePage(),
  };

  late final Map<AppTab, Widget> _pages = {
    for (final tab in AppTab.values) tab: _pageFor(tab),
  };

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    // Listen for achievements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AchievementProvider>();
      _achievementSubscription = provider.onAchievementUnlocked.listen(
        _queueAchievementNotification,
      );

      // Check if first-launch onboarding should be shown.
      final settings = context.read<SettingsProvider>();
      if (!settings.onboardingCompleted) {
        if (locator.isRegistered<Isar>()) {
          if (hasExistingUserDataInIsar(locator<Isar>())) {
            unawaited(settings.setOnboardingCompleted(true));
          } else {
            _isOnboardingActive = true;
            unawaited(_showOnboarding());
          }
        } else {
          _isOnboardingActive = true;
          unawaited(_maybeShowOnboarding());
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _achievementSubscription?.cancel();
    _achievementQueue.clear();
    _closeNotification();
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
      await Future<void>.delayed(const Duration(milliseconds: 300));
      unawaited(_processAchievementQueue());
    }
  }

  Future<void> _showTopNotification(Achievement achievement) async {
    if (!mounted) return;

    final completer = _notificationDone = Completer<void>();
    final mainPageContext = context;

    _currentNotification = OverlayEntry(
      builder: (context) => _AchievementTopBanner(
        key: ValueKey('achievement_banner_${achievement.id}'),
        achievement: achievement,
        mainPageContext: mainPageContext,
        onDismiss: _closeNotification,
      ),
    );

    Overlay.of(context).insert(_currentNotification!);

    return completer.future;
  }

  /// Removes the banner on screen, if any, and releases the queue. Runs once
  /// per banner whatever closes it first (its dismissal, page disposed).
  void _closeNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
    final done = _notificationDone;
    _notificationDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('[MainPage] getInitialLink failed: $e');
    }

    // Handle subsequent links
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.path == '/share' ||
        (uri.scheme == 'mediavore' && uri.host == 'share')) {
      if (_isOnboardingActive) {
        _pendingDeepLink = uri;
        return;
      }
      final payload = ListShareCodec.decodeUri(uri);
      if (payload != null && payload.entries.isNotEmpty) {
        showIncomingListOptionsSheet(
          context: context,
          payload: payload,
          onImportComplete: () {
            if (mounted) {
              final provider = context.read<SearchProvider>();
              provider.openLibrary(LibrarySection.lists);
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final requested = context.select<SearchProvider, AppTab>(
      (provider) => provider.selectedTab,
    );
    // A tab that is not shown (see kShowTogetherTab) falls back to the first.
    final selected = tabs.contains(requested) ? requested : tabs.first;
    // A running vote is full screen: no tab can be tapped by accident.
    final voting = context.select<TogetherSessionProvider, bool>(
      (session) => session.isVoting,
    );

    return Scaffold(
      body: IndexedStack(
        index: tabs.indexOf(selected),
        children: [for (final tab in tabs) _pages[tab]!],
      ),
      bottomNavigationBar: voting
          ? null
          : AppTabBar(
              tabs: tabs,
              selected: selected,
              onSelected: context.read<SearchProvider>().setSelectedTab,
            ),
    );
  }

  /// First-launch onboarding flow (async fallback when Isar is not registered,
  /// e.g. mocked widget tests). Skips automatically for existing users.
  Future<void> _maybeShowOnboarding() async {
    try {
      final settings = context.read<SettingsProvider>();
      final repo = context.read<SearchProvider>().repository;
      if (await _hasExistingUserData(repo)) {
        await settings.setOnboardingCompleted(true);
        return;
      }
      if (!mounted) return;
      await _pushOnboarding();
    } finally {
      _finishOnboardingWait();
    }
  }

  /// Pushes [OnboardingPage] and shows the TMDB reminder if no key was saved.
  Future<void> _showOnboarding() async {
    try {
      await _pushOnboarding();
    } finally {
      _finishOnboardingWait();
    }
  }

  Future<void> _pushOnboarding() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OnboardingPage(),
      ),
    );
    if (!mounted) return;

    if (context.read<SettingsProvider>().tmdbApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tmdbCredentialLater),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _finishOnboardingWait() {
    _isOnboardingActive = false;
    final pending = _pendingDeepLink;
    _pendingDeepLink = null;
    if (pending != null && mounted) {
      _handleLink(pending);
    }
  }

  Future<bool> _hasExistingUserData(MediaRepository repo) async {
    final seen = await repo.getSeenItems();
    if (seen.isNotEmpty) return true;
    final lists = await repo.getAllListNames();
    for (final name in lists) {
      if (name != 'watchlist') return true;
      final entries = await repo.getListEntries(name);
      if (entries.isNotEmpty) return true;
    }
    final notified = await repo.getNotifiedItems();
    if (notified.isNotEmpty) return true;
    final liked = await repo.getLikedEntries();
    if (liked.isNotEmpty) return true;
    return false;
  }
}

class _AchievementTopBanner extends StatefulWidget {
  final Achievement achievement;
  final BuildContext mainPageContext;
  final VoidCallback onDismiss;

  const _AchievementTopBanner({
    super.key,
    required this.achievement,
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

  /// Dismisses the banner after 4 s.
  Timer? _autoDismiss;

  /// Set by the first dismissal (tap, swipe, timer); later ones are ignored.
  bool _dismissing = false;

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
    _autoDismiss = Timer(const Duration(seconds: 4), _handleDismiss);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismiss?.cancel();
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final onToast = colors.onPrimary;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const appBarHeight = kToolbarHeight;

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
      final provider = widget.mainPageContext.read<SearchProvider>();
      if (provider.selectedTab == AppTab.library) {
        // Library title, segment and type chips instead of an app bar, plus
        // the app bar and the search bar of the history.
        topOffset += 96;
        if (provider.librarySection == LibrarySection.history) {
          topOffset += 116;
        }
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
              if (_dismissing) return;
              AchievementsPage.showAchievement(
                Navigator.of(context),
                widget.achievement.id,
              );
              unawaited(_handleDismiss());
            },
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < -10) {
                unawaited(_handleDismiss());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primary,
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
                  Icon(Icons.emoji_events, color: onToast, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.achievement.tier != null
                              ? context.l10n.achievementLevelUnlocked(
                                  widget.achievement.tier!,
                                )
                              : context.l10n.achievementUnlocked,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: onToast,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.achievement.titleFor(context.l10n.localeName),
                          style: TextStyle(color: onToast, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: onToast.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    tooltip: context.l10n.commonClose,
                    onPressed: () => unawaited(_handleDismiss()),
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
