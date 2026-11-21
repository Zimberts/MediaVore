import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Represents a candidate movie or series in a Together vote.
@immutable
class TogetherVoteCandidate {
  const TogetherVoteCandidate({required this.item});

  final MediaItem item;

  String get key => '${item.id}:${item.mediaType.name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TogetherVoteCandidate &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// A ranked candidate after all participants have voted.
@immutable
class TogetherVoteResultItem {
  const TogetherVoteResultItem({
    required this.candidate,
    required this.approvalCount,
    this.isTied = false,
  });

  final TogetherVoteCandidate candidate;
  final int approvalCount;
  final bool isTied;
}

/// Turn-by-turn state machine for a Together swipe vote.
///
/// Cycles through each participant, letting them vote (Oui / Non) on up to 6
/// candidate titles without seeing anyone else's votes. Once everyone has
/// voted, compiles the rankings by approval count (and TMDB rating for ties).
class TogetherVoteEngine extends ChangeNotifier {
  TogetherVoteEngine({
    required List<TogetherVoteCandidate> candidates,
    required List<String> participants,
  }) : assert(candidates.isNotEmpty, 'Candidates cannot be empty'),
       assert(participants.isNotEmpty, 'Participants cannot be empty'),
       _candidates = List.unmodifiable(candidates.take(6)),
       _participants = List.unmodifiable(participants),
       _votes = {for (final p in participants) p: <String>{}};

  final List<TogetherVoteCandidate> _candidates;
  final List<String> _participants;
  final Map<String, Set<String>> _votes;

  int _currentParticipantIndex = 0;
  int _currentCandidateIndex = 0;
  bool _isTransition = true;
  bool _isFinished = false;

  List<TogetherVoteCandidate> get candidates => _candidates;
  List<String> get participants => _participants;
  Map<String, Set<String>> get votes => _votes;

  int get currentParticipantIndex => _currentParticipantIndex;
  int get currentCandidateIndex => _currentCandidateIndex;
  bool get isTransition => _isTransition;
  bool get isFinished => _isFinished;

  String get currentParticipant => _participants[_currentParticipantIndex];
  TogetherVoteCandidate get currentCandidate =>
      _candidates[_currentCandidateIndex];

  bool get isHostTurn => _currentParticipantIndex == 0;

  int get totalVotesExpected => _participants.length * _candidates.length;

  int get totalVotesCast {
    var count = _currentParticipantIndex * _candidates.length;
    if (!_isTransition && !_isFinished) {
      count += _currentCandidateIndex;
    } else if (_isFinished) {
      count = totalVotesExpected;
    }
    return count;
  }

  /// Begins the voting round for the current participant.
  void startTurn() {
    if (!_isTransition || _isFinished) return;
    _isTransition = false;
    notifyListeners();
  }

  /// Casts an approval (Oui) or disapproval (Non) for the current candidate
  /// by the current participant, and advances to the next candidate or voter.
  void castVote(bool approve) {
    if (_isTransition || _isFinished) return;

    final voter = currentParticipant;
    final candidateKey = currentCandidate.key;
    if (approve) {
      _votes[voter]!.add(candidateKey);
    } else {
      _votes[voter]!.remove(candidateKey);
    }

    if (_currentCandidateIndex + 1 < _candidates.length) {
      _currentCandidateIndex++;
    } else {
      // Completed all candidates for current voter
      if (_currentParticipantIndex + 1 < _participants.length) {
        _currentParticipantIndex++;
        _currentCandidateIndex = 0;
        _isTransition = true;
      } else {
        _isFinished = true;
      }
    }
    notifyListeners();
  }

  /// Calculates the final rankings sorted by approval count descending,
  /// then by TMDB vote average descending. Flags any tie for 1st place.
  List<TogetherVoteResultItem> getResults() {
    final results = <TogetherVoteResultItem>[];

    for (final candidate in _candidates) {
      var approvals = 0;
      for (final p in _participants) {
        if (_votes[p]?.contains(candidate.key) ?? false) {
          approvals++;
        }
      }
      results.add(
        TogetherVoteResultItem(candidate: candidate, approvalCount: approvals),
      );
    }

    // Sort by approvals desc, then TMDB vote average desc
    results.sort((a, b) {
      final cmp = b.approvalCount.compareTo(a.approvalCount);
      if (cmp != 0) return cmp;
      final ratingA = a.candidate.item.voteAverage ?? 0.0;
      final ratingB = b.candidate.item.voteAverage ?? 0.0;
      return ratingB.compareTo(ratingA);
    });

    if (results.isEmpty) return const [];

    final topApprovals = results[0].approvalCount;
    final topRating = results[0].candidate.item.voteAverage ?? 0.0;

    // A tie occurs if more than one candidate shares the top approvals and rating
    final hasTieForFirst =
        results.length > 1 &&
        results[1].approvalCount == topApprovals &&
        (results[1].candidate.item.voteAverage ?? 0.0) == topRating;

    final formatted = <TogetherVoteResultItem>[];
    for (var i = 0; i < results.length; i++) {
      final item = results[i];
      final isTied =
          hasTieForFirst &&
          item.approvalCount == topApprovals &&
          (item.candidate.item.voteAverage ?? 0.0) == topRating;
      formatted.add(
        TogetherVoteResultItem(
          candidate: item.candidate,
          approvalCount: item.approvalCount,
          isTied: isTied,
        ),
      );
    }

    return formatted;
  }

  /// Whether the [winner] received approvals from every participant.
  bool isUnanimous(TogetherVoteResultItem winner) {
    return _participants.isNotEmpty &&
        winner.approvalCount == _participants.length;
  }
}
