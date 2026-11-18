import 'package:flutter/foundation.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/home/presentation/in_progress_sort.dart';

/// Filters and sort of the pages opened from Home, kept for the session:
/// leaving a page and coming back finds it as it was left.
class HomeSessionProvider extends ChangeNotifier {
  MediaKind? _inProgressKind;
  InProgressSort _inProgressSort = InProgressSort.recent;
  bool _inProgressPausedOnly = false;
  MediaKind? _upcomingKind;

  /// Kind shown on "In progress"; `null` = all kinds.
  MediaKind? get inProgressKind => _inProgressKind;

  InProgressSort get inProgressSort => _inProgressSort;

  /// Only the titles without activity for more than 30 days.
  bool get inProgressPausedOnly => _inProgressPausedOnly;

  void setInProgressKind(MediaKind? kind) {
    if (_inProgressKind == kind) return;
    _inProgressKind = kind;
    notifyListeners();
  }

  void setInProgressSort(InProgressSort sort) {
    if (_inProgressSort == sort) return;
    _inProgressSort = sort;
    notifyListeners();
  }

  void setInProgressPausedOnly(bool pausedOnly) {
    if (_inProgressPausedOnly == pausedOnly) return;
    _inProgressPausedOnly = pausedOnly;
    notifyListeners();
  }

  /// Kind shown on "Upcoming"; `null` = all kinds.
  MediaKind? get upcomingKind => _upcomingKind;

  void setUpcomingKind(MediaKind? kind) {
    if (_upcomingKind == kind) return;
    _upcomingKind = kind;
    notifyListeners();
  }
}
