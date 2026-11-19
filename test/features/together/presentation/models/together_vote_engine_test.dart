import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/together/presentation/models/together_vote_engine.dart';

void main() {
  MediaItem item(int id, String title, {double rating = 7.0}) {
    return MediaItem(
      id: id,
      title: title,
      overview: 'Overview $id',
      releaseDate: '2023-01-01',
      mediaType: MediaType.movie,
      voteAverage: rating,
    );
  }

  group('TogetherVoteEngine', () {
    test('cycles 3 voters and 6 titles for exactly 18 votes and finishes', () {
      final candidates = List.generate(
        6,
        (i) => TogetherVoteCandidate(item: item(i + 1, 'Movie ${i + 1}')),
      );
      final participants = ['Host', 'Alice', 'Bob'];

      final engine = TogetherVoteEngine(
        candidates: candidates,
        participants: participants,
      );

      var notificationCount = 0;
      engine.addListener(() => notificationCount++);

      expect(engine.isFinished, isFalse);
      expect(engine.isTransition, isTrue);
      expect(engine.isHostTurn, isTrue);
      expect(engine.currentParticipant, 'Host');

      var totalVotes = 0;

      for (var p = 0; p < participants.length; p++) {
        expect(engine.isTransition, isTrue);
        expect(engine.currentParticipantIndex, p);
        engine.startTurn();
        expect(engine.isTransition, isFalse);

        for (var c = 0; c < candidates.length; c++) {
          expect(engine.currentCandidateIndex, c);
          // Alternate yes/no
          engine.castVote(c % 2 == 0);
          totalVotes++;
        }
      }

      expect(totalVotes, 18);
      expect(engine.totalVotesCast, 18);
      expect(engine.isFinished, isTrue);
      expect(notificationCount, greaterThan(0));

      final results = engine.getResults();
      expect(results, hasLength(6));
      expect(results.first.candidate.item.id, isNotNull);
    });

    test('breaks tie by TMDB vote average', () {
      // Both candidates get 2 votes, but Movie 2 has higher TMDB rating
      final c1 = TogetherVoteCandidate(
        item: item(1, 'Movie 1', rating: 7.0),
      );
      final c2 = TogetherVoteCandidate(
        item: item(2, 'Movie 2', rating: 8.5),
      );

      final engine = TogetherVoteEngine(
        candidates: [c1, c2],
        participants: ['Host', 'Alice'],
      );

      // Host votes Yes for both
      engine.startTurn();
      engine.castVote(true); // C1
      engine.castVote(true); // C2

      // Alice votes Yes for both
      engine.startTurn();
      engine.castVote(true); // C1
      engine.castVote(true); // C2

      expect(engine.isFinished, isTrue);

      final results = engine.getResults();
      expect(results[0].candidate.item.id, 2); // Higher rating wins tie
      expect(results[1].candidate.item.id, 1);
      expect(results[0].isTied, isFalse);
      expect(engine.isUnanimous(results[0]), isTrue);
    });

    test('detects tie for first place when both approvals and rating match', () {
      final c1 = TogetherVoteCandidate(
        item: item(1, 'Movie 1', rating: 8.0),
      );
      final c2 = TogetherVoteCandidate(
        item: item(2, 'Movie 2', rating: 8.0),
      );

      final engine = TogetherVoteEngine(
        candidates: [c1, c2],
        participants: ['Host', 'Alice'],
      );

      engine.startTurn();
      engine.castVote(true);
      engine.castVote(true);

      engine.startTurn();
      engine.castVote(true);
      engine.castVote(true);

      final results = engine.getResults();
      expect(results[0].isTied, isTrue);
      expect(results[1].isTied, isTrue);
    });

    test('handles single candidate without error', () {
      final c1 = TogetherVoteCandidate(item: item(1, 'Solo'));
      final engine = TogetherVoteEngine(
        candidates: [c1],
        participants: ['Host'],
      );

      engine.startTurn();
      engine.castVote(true);

      expect(engine.isFinished, isTrue);
      final results = engine.getResults();
      expect(results, hasLength(1));
      expect(results.first.approvalCount, 1);
      expect(engine.isUnanimous(results.first), isTrue);
    });
  });
}
