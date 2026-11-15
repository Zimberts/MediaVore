import 'package:flutter/foundation.dart';
import 'package:mediavore/core/widgets/media_kind.dart';

/// What the user decided for a swiped title.
enum SwipeDecisionKind { added, passed }

/// One decision of the swipe session.
@immutable
class SwipeDecision {
  const SwipeDecision({
    required this.mediaKey,
    required this.kind,
    required this.at,
  });

  /// Stable key of the title (`<tmdbId>:<type>`).
  final String mediaKey;
  final SwipeDecisionKind kind;
  final DateTime at;
}

/// State of the swipe session: filter, decisions and undo stack.
///
/// Provided at app level, not held by the screen, so that it survives a
/// change of tab. Kept in memory for now; the Swiper issue backs it with the
/// persistent decision journal.
class SwipeSessionProvider extends ChangeNotifier {
  MediaKind? _filter;
  final List<SwipeDecision> _decisions = [];

  /// Media type shown by the deck; `null` shows everything.
  MediaKind? get filter => _filter;

  /// Decisions of the session, oldest first. The last one is undone first.
  List<SwipeDecision> get decisions => List.unmodifiable(_decisions);

  int get addedCount =>
      _decisions.where((d) => d.kind == SwipeDecisionKind.added).length;

  int get passedCount =>
      _decisions.where((d) => d.kind == SwipeDecisionKind.passed).length;

  bool get canUndo => _decisions.isNotEmpty;

  void setFilter(MediaKind? filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void record(SwipeDecision decision) {
    _decisions.add(decision);
    notifyListeners();
  }

  /// Removes and returns the latest decision, or `null` when there is none.
  SwipeDecision? undo() {
    if (_decisions.isEmpty) return null;
    final decision = _decisions.removeLast();
    notifyListeners();
    return decision;
  }

  /// Starts a new session; the filter is kept.
  void reset() {
    if (_decisions.isEmpty) return;
    _decisions.clear();
    notifyListeners();
  }
}
