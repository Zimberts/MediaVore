import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';

/// Whether "Together" is a tab of its own.
///
/// Pending product decision: single switch, nothing else depends on the
/// position or on the number of tabs.
const bool kShowTogetherTab = true;

/// Tabs of the app shell, in the order of the design.
///
/// Always refer to a tab by its value, never by its position.
enum AppTab {
  home,
  discover,
  library,
  together,
  me;

  /// Tabs shown in the bar, in order.
  static List<AppTab> get visibleTabs => kShowTogetherTab
      ? values
      : values.where((tab) => tab != AppTab.together).toList();

  /// Tab the app opens on.
  static const AppTab initial = AppTab.home;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.home => l10n.navHome,
    AppTab.discover => l10n.navDiscover,
    AppTab.library => l10n.navLibrary,
    AppTab.together => l10n.navTogether,
    AppTab.me => l10n.navMe,
  };

  IconData get icon => switch (this) {
    AppTab.home => Icons.home_outlined,
    AppTab.discover => Icons.explore_outlined,
    AppTab.library => Icons.collections_bookmark_outlined,
    AppTab.together => Icons.group_outlined,
    AppTab.me => Icons.person_outline,
  };

  IconData get selectedIcon => switch (this) {
    AppTab.home => Icons.home,
    AppTab.discover => Icons.explore,
    AppTab.library => Icons.collections_bookmark,
    AppTab.together => Icons.group,
    AppTab.me => Icons.person,
  };
}

/// Sections of the Library tab.
enum LibrarySection { lists, history }
