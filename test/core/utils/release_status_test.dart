import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/release_status.dart';

MediaItem _item(String releaseDate, {MediaType type = MediaType.movie}) =>
    MediaItem(
      id: 1,
      title: 'Title',
      overview: '',
      releaseDate: releaseDate,
      mediaType: type,
    );

void main() {
  final now = DateTime(2026, 11, 21, 22, 30);

  group('isReleased', () {
    test('should be true for a past release', () {
      expect(isReleased(_item('2021-10-22'), now), isTrue);
    });

    test('should be true for a release dated today, whatever the time', () {
      expect(isReleased(_item('2026-11-21'), now), isTrue);
      expect(isReleased(_item('2026-11-21'), DateTime(2026, 11, 21)), isTrue);
    });

    test('should be false for a release dated tomorrow or later', () {
      expect(isReleased(_item('2026-11-22'), now), isFalse);
      expect(isReleased(_item('2026-12-15'), now), isFalse);
    });

    test('should be false for an empty or unparsable date', () {
      expect(isReleased(_item(''), now), isFalse);
      expect(isReleased(_item('soon'), now), isFalse);
    });

    test('should use the first air date of a series', () {
      expect(isReleased(_item('2027-01-10', type: MediaType.tv), now), isFalse);
      expect(isReleased(_item('2016-07-15', type: MediaType.tv), now), isTrue);
    });
  });
}
