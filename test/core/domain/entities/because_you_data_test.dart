import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

void main() {
  group('BecauseYouData', () {
    test('toJson and fromJson roundtrip', () {
      const data = BecauseYouData(
        sourceId: 438631,
        sourceType: MediaType.movie,
        sourceTitle: 'Dune',
        reason: BecauseYouReason.liked,
        items: [
          MediaItem(
            id: 1,
            title: 'Blade Runner 2049',
            overview: '',
            releaseDate: '2017',
          ),
          MediaItem(id: 2, title: 'Arrival', overview: '', releaseDate: '2016'),
          MediaItem(id: 3, title: 'Sicario', overview: '', releaseDate: '2015'),
        ],
      );

      final json = data.toJson();
      final parsed = BecauseYouData.fromJson(json);

      expect(parsed, equals(data));
      expect(parsed.sourceTitle, 'Dune');
      expect(parsed.reason, BecauseYouReason.liked);
      expect(parsed.items.length, 3);
    });
  });
}
