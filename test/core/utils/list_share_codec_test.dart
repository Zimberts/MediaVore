import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';

void main() {
  group('ListShareCodec', () {
    test('encodeV2 and decodeV2 roundtrip with movies and tv shows', () {
      final original = [
        const SharedMediaEntry(100, MediaType.movie),
        const SharedMediaEntry(105, MediaType.movie),
        const SharedMediaEntry(200, MediaType.movie),
        const SharedMediaEntry(
          100,
          MediaType.tv,
        ), // Same numeric ID, different type
        const SharedMediaEntry(350, MediaType.tv),
      ];

      final encoded = ListShareCodec.encodeV2(original);
      expect(encoded, isNotEmpty);
      expect(encoded.contains('='), isFalse); // padding stripped

      final decoded = ListShareCodec.decodeV2(encoded);
      expect(decoded.length, 5);
      expect(decoded, contains(const SharedMediaEntry(100, MediaType.movie)));
      expect(decoded, contains(const SharedMediaEntry(105, MediaType.movie)));
      expect(decoded, contains(const SharedMediaEntry(200, MediaType.movie)));
      expect(decoded, contains(const SharedMediaEntry(100, MediaType.tv)));
      expect(decoded, contains(const SharedMediaEntry(350, MediaType.tv)));
    });

    test('encodeV2 handles empty entries', () {
      final encoded = ListShareCodec.encodeV2([]);
      final decoded = ListShareCodec.decodeV2(encoded);
      expect(decoded, isEmpty);
    });

    test('decodeV2 handles malformed data gracefully without throwing', () {
      expect(ListShareCodec.decodeV2(''), isEmpty);
      expect(ListShareCodec.decodeV2('not-valid-base64!@#%^&*'), isEmpty);
      expect(ListShareCodec.decodeV2('dG9vLXNob3J0'), isEmpty);
    });

    test('decodeV1 parses comma-separated id:type correctly', () {
      const v1String = '101:movie,202:tv,invalid,303:movie';
      final entries = ListShareCodec.decodeV1(v1String);

      expect(entries.length, 3);
      expect(entries[0], const SharedMediaEntry(101, MediaType.movie));
      expect(entries[1], const SharedMediaEntry(202, MediaType.tv));
      expect(entries[2], const SharedMediaEntry(303, MediaType.movie));
    });

    test('decodeUri handles both v1 and v2 URLs and custom schemes', () {
      // v1
      final uriV1 = Uri.parse(
        'https://mediavore.app/share?name=TestList&items=10:movie,20:tv',
      );
      final payloadV1 = ListShareCodec.decodeUri(uriV1);
      expect(payloadV1, isNotNull);
      expect(payloadV1!.name, 'TestList');
      expect(payloadV1.entries.length, 2);

      // v2
      final entries = [
        const SharedMediaEntry(55, MediaType.movie),
        const SharedMediaEntry(77, MediaType.tv),
      ];
      final urlV2 = ListShareCodec.createShareUrl(
        listName: 'Summer Watchlist',
        entries: entries,
        customScheme: true,
        version: 2,
      );
      expect(urlV2, startsWith('mediavore://share?v=2'));

      final uriV2 = Uri.parse(urlV2);
      final payloadV2 = ListShareCodec.decodeUri(uriV2);
      expect(payloadV2, isNotNull);
      expect(payloadV2!.name, 'Summer Watchlist');
      expect(payloadV2.version, 2);
      expect(
        payloadV2.entries,
        contains(const SharedMediaEntry(55, MediaType.movie)),
      );
      expect(
        payloadV2.entries,
        contains(const SharedMediaEntry(77, MediaType.tv)),
      );
    });

    test('v2 encoding size is much more compact than v1 for large lists', () {
      final entries = List.generate(
        100,
        (i) => SharedMediaEntry(
          1000 + i * 5,
          i % 2 == 0 ? MediaType.movie : MediaType.tv,
        ),
      );

      final v1Url = ListShareCodec.createShareUrl(
        listName: 'Huge',
        entries: entries,
        version: 1,
      );
      final v2Url = ListShareCodec.createShareUrl(
        listName: 'Huge',
        entries: entries,
        version: 2,
      );

      // v1 is typically > 1500 chars, v2 is ~150-250 chars
      expect(v2Url.length, lessThan(v1Url.length ~/ 4));
    });
  });
}
