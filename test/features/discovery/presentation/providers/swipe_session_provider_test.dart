import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/discovery/presentation/providers/swipe_session_provider.dart';

void main() {
  late SwipeSessionProvider session;
  late int notifications;

  SwipeDecision decision(String key, SwipeDecisionKind kind) =>
      SwipeDecision(mediaKey: key, kind: kind, at: DateTime(2026, 11, 14));

  setUp(() {
    session = SwipeSessionProvider();
    notifications = 0;
    session.addListener(() => notifications++);
  });

  group('SwipeSessionProvider', () {
    test('should start without filter nor decision', () {
      expect(session.filter, isNull);
      expect(session.decisions, isEmpty);
      expect(session.canUndo, isFalse);
      expect(session.undo(), isNull);
      expect(notifications, 0);
    });

    test('should notify only when the filter changes', () {
      session.setFilter(MediaKind.film);
      session.setFilter(MediaKind.film);

      expect(session.filter, MediaKind.film);
      expect(notifications, 1);
    });

    test('should count decisions by kind', () {
      session.record(decision('1:movie', SwipeDecisionKind.added));
      session.record(decision('2:movie', SwipeDecisionKind.passed));
      session.record(decision('3:tv', SwipeDecisionKind.passed));

      expect(session.addedCount, 1);
      expect(session.passedCount, 2);
      expect(notifications, 3);
    });

    test('should undo decisions from the most recent one', () {
      session.record(decision('1:movie', SwipeDecisionKind.added));
      session.record(decision('2:movie', SwipeDecisionKind.passed));

      expect(session.undo()?.mediaKey, '2:movie');
      expect(session.passedCount, 0);
      expect(session.undo()?.mediaKey, '1:movie');
      expect(session.canUndo, isFalse);
    });

    test('should not expose its decision list for mutation', () {
      session.record(decision('1:movie', SwipeDecisionKind.added));

      expect(() => session.decisions.clear(), throwsUnsupportedError);
    });

    test('should keep the filter when the session is reset', () {
      session.setFilter(MediaKind.serie);
      session.record(decision('1:tv', SwipeDecisionKind.added));

      session.reset();

      expect(session.decisions, isEmpty);
      expect(session.filter, MediaKind.serie);
    });
  });
}
