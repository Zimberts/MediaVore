import 'package:flutter/foundation.dart';

/// Someone taking part in a "Together" session, with the list they shared.
@immutable
class TogetherParticipant {
  const TogetherParticipant({required this.name, this.entries = const []});

  final String name;

  /// Shared titles, as `<tmdbId>:<type>` keys.
  final List<String> entries;
}

/// State of the "Together" session: participants, votes and whether a vote
/// is running.
///
/// Provided at app level, not held by the screen, so that it survives a
/// change of tab. Nothing is persisted: the session lives in memory until
/// [reset]. The shell hides the tab bar while [isVoting].
class TogetherSessionProvider extends ChangeNotifier {
  final List<TogetherParticipant> _participants = [];
  final Map<String, Set<String>> _votes = {};
  bool _isVoting = false;

  List<TogetherParticipant> get participants =>
      List.unmodifiable(_participants);

  /// Titles each participant voted for, by participant name.
  Map<String, Set<String>> get votes => {
    for (final entry in _votes.entries)
      entry.key: Set.unmodifiable(entry.value),
  };

  bool get isVoting => _isVoting;

  bool get hasSession => _participants.isNotEmpty;

  void addParticipant(TogetherParticipant participant) {
    _participants.removeWhere((p) => p.name == participant.name);
    _participants.add(participant);
    notifyListeners();
  }

  void removeParticipant(String name) {
    final before = _participants.length;
    _participants.removeWhere((p) => p.name == name);
    final hadVotes = _votes.remove(name) != null;
    if (before != _participants.length || hadVotes) notifyListeners();
  }

  void startVote() {
    if (_isVoting) return;
    _isVoting = true;
    notifyListeners();
  }

  void castVote(String participant, String mediaKey, {bool approve = true}) {
    final votes = _votes.putIfAbsent(participant, () => <String>{});
    final changed = approve ? votes.add(mediaKey) : votes.remove(mediaKey);
    if (changed) notifyListeners();
  }

  /// Leaves the vote. Participants stay in the session; votes are dropped
  /// unless [keepVotes].
  void endVote({bool keepVotes = false}) {
    if (!_isVoting && (keepVotes || _votes.isEmpty)) return;
    _isVoting = false;
    if (!keepVotes) _votes.clear();
    notifyListeners();
  }

  /// Ends the session: participants and votes are forgotten.
  void reset() {
    if (!hasSession && _votes.isEmpty && !_isVoting) return;
    _participants.clear();
    _votes.clear();
    _isVoting = false;
    notifyListeners();
  }
}
