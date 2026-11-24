import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
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
        const TogetherParticipant(
          name: 'Lea',
          entries: [SharedMediaEntry(1, MediaType.movie)],
        ),
      );
      session.addParticipant(
        const TogetherParticipant(
          name: 'Lea',
          entries: [SharedMediaEntry(2, MediaType.tv)],
        ),
      );

      expect(session.participants, hasLength(1));
      expect(session.participants.single.entries, [
        const SharedMediaEntry(2, MediaType.tv),
      ]);
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
      session.endVote();
      session.removeParticipant('Nobody');

      expect(notifications, 0);
    });

    test('should compute participant initials correctly', () {
      expect(const TogetherParticipant(name: 'Alexis Imbert').initials, 'AI');
      expect(const TogetherParticipant(name: 'Lea').initials, 'LE');
      expect(const TogetherParticipant(name: 'A').initials, 'A');
      expect(const TogetherParticipant(name: '   ').initials, '?');
    });

    test('should accumulate multi-part chunks', () {
      session.addParticipantChunk(
        name: 'Bob',
        part: 1,
        totalParts: 2,
        entries: const [SharedMediaEntry(101, MediaType.movie)],
      );

      expect(session.participants, hasLength(1));
      expect(session.participants.first.isComplete, isFalse);
      expect(session.participants.first.entries, hasLength(1));

      session.addParticipantChunk(
        name: 'Bob',
        part: 2,
        totalParts: 2,
        entries: const [SharedMediaEntry(102, MediaType.tv)],
      );

      expect(session.participants, hasLength(1));
      expect(session.participants.first.isComplete, isTrue);
      expect(session.participants.first.entries, hasLength(2));
    });

    test('should keep two friends apart when their QR codes share a name', () {
      final first = session.addParticipantChunk(
        name: 'Friend',
        part: 1,
        totalParts: 1,
        entries: const [SharedMediaEntry(101, MediaType.movie)],
      );
      final second = session.addParticipantChunk(
        name: 'Friend',
        part: 1,
        totalParts: 1,
        entries: const [SharedMediaEntry(102, MediaType.movie)],
      );

      expect((first, second), ('Friend', 'Friend 2'));
      expect(
        [for (final p in session.participants) (p.name, p.entries.length)],
        [('Friend', 1), ('Friend 2', 1)],
      );
    });

    test('should ignore a QR code scanned twice', () {
      for (var i = 0; i < 2; i++) {
        session.addParticipantChunk(
          name: 'Friend',
          part: 1,
          totalParts: 1,
          entries: const [SharedMediaEntry(101, MediaType.movie)],
        );
      }

      expect(session.participants, hasLength(1));
    });

    test('should not give a participant a reserved name', () {
      final name = session.addParticipantChunk(
        name: 'Me (Host)',
        part: 1,
        totalParts: 1,
        entries: const [SharedMediaEntry(101, MediaType.movie)],
        reservedNames: {'Me (Host)'},
      );

      expect(name, 'Me (Host) 2');
      expect(session.participants.single.name, 'Me (Host) 2');
    });

    test('should start a new participant when a complete one gets a part', () {
      session.addParticipantChunk(
        name: 'Friend',
        part: 1,
        totalParts: 1,
        entries: const [SharedMediaEntry(101, MediaType.movie)],
      );
      session.addParticipantChunk(
        name: 'Friend',
        part: 1,
        totalParts: 2,
        entries: const [SharedMediaEntry(201, MediaType.movie)],
      );
      final name = session.addParticipantChunk(
        name: 'Friend',
        part: 2,
        totalParts: 2,
        entries: const [SharedMediaEntry(202, MediaType.movie)],
      );

      expect(name, 'Friend 2');
      expect(
        [
          for (final p in session.participants)
            (p.name, p.entries.length, p.isComplete),
        ],
        [('Friend', 1, true), ('Friend 2', 2, true)],
      );
    });

    test('should update type filter, list name and hide seen', () {
      session.setSelectedType(MediaType.movie);
      expect(session.selectedType, MediaType.movie);

      session.setSelectedListName('favorites');
      expect(session.selectedListName, 'favorites');

      session.setHideSeen(true);
      expect(session.hideSeen, isTrue);

      session.reset();
      expect(session.selectedType, isNull);
      expect(session.selectedListName, 'watchlist');
      expect(session.hideSeen, isFalse);
    });
  });
}
