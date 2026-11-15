import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';

void main() {
  late TogetherSessionProvider session;
  late int notifications;

  setUp(() {
    session = TogetherSessionProvider();
    notifications = 0;
    session.addListener(() => notifications++);
  });

  group('TogetherSessionProvider', () {
    test('should start empty and not voting', () {
      expect(session.hasSession, isFalse);
      expect(session.participants, isEmpty);
      expect(session.votes, isEmpty);
      expect(session.isVoting, isFalse);
    });

    test('should replace a participant scanned twice', () {
      session.addParticipant(
        const TogetherParticipant(name: 'Lea', entries: ['1:movie']),
      );
      session.addParticipant(
        const TogetherParticipant(name: 'Lea', entries: ['2:tv']),
      );

      expect(session.participants, hasLength(1));
      expect(session.participants.single.entries, ['2:tv']);
    });

    test('should record and withdraw votes', () {
      session.castVote('Lea', '1:movie');
      session.castVote('Lea', '1:movie');
      session.castVote('Tom', '1:movie');
      session.castVote('Tom', '2:tv');
      session.castVote('Tom', '2:tv', approve: false);

      expect(session.votes, {
        'Lea': {'1:movie'},
        'Tom': {'1:movie'},
      });
      expect(notifications, 4);
    });

    test('should drop the votes of a removed participant', () {
      session.addParticipant(const TogetherParticipant(name: 'Lea'));
      session.castVote('Lea', '1:movie');

      session.removeParticipant('Lea');

      expect(session.participants, isEmpty);
      expect(session.votes, isEmpty);
    });

    test('should keep participants and drop votes when a vote is left', () {
      session.addParticipant(const TogetherParticipant(name: 'Lea'));
      session.startVote();
      session.castVote('Lea', '1:movie');
      expect(session.isVoting, isTrue);

      session.endVote();

      expect(session.isVoting, isFalse);
      expect(session.votes, isEmpty);
      expect(session.participants, hasLength(1));
    });

    test('should keep the votes of a finished vote when asked to', () {
      session.startVote();
      session.castVote('Lea', '1:movie');

      session.endVote(keepVotes: true);

      expect(session.isVoting, isFalse);
      expect(session.votes, {
        'Lea': {'1:movie'},
      });
    });

    test('should forget everything on reset', () {
      session.addParticipant(const TogetherParticipant(name: 'Lea'));
      session.startVote();
      session.castVote('Lea', '1:movie');

      session.reset();

      expect(session.hasSession, isFalse);
      expect(session.votes, isEmpty);
      expect(session.isVoting, isFalse);
    });

    test('should not notify when nothing changes', () {
      session.reset();
      session.endVote();
      session.removeParticipant('Nobody');

      expect(notifications, 0);
    });
  });
}
