import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/watch_providers.dart';

void main() {
  group('WatchProviders', () {
    const multiCountryJson = {
      'results': {
        'FR': {
          'link': 'https://www.themoviedb.org/movie/550/watch?locale=FR',
          'flatrate': [
            {
              'logo_path': '/netflix.jpg',
              'provider_id': 8,
              'provider_name': 'Netflix',
              'display_priority': 0,
            },
            {
              'logo_path': '/canal.jpg',
              'provider_id': 381,
              'provider_name': 'Canal+',
              'display_priority': 1,
            },
          ],
          'rent': [
            {
              'logo_path': '/appletv.jpg',
              'provider_id': 2,
              'provider_name': 'Apple TV',
              'display_priority': 2,
            },
          ],
          'buy': [
            {
              'logo_path': '/appletv.jpg',
              'provider_id': 2,
              'provider_name': 'Apple TV',
              'display_priority': 2,
            },
          ],
        },
        'US': {
          'link': 'https://www.themoviedb.org/movie/550/watch?locale=US',
          'flatrate': [
            {
              'logo_path': '/hulu.jpg',
              'provider_id': 15,
              'provider_name': 'Hulu',
              'display_priority': 1,
            },
          ],
        },
        'GB': {
          'link': 'https://www.themoviedb.org/movie/550/watch?locale=GB',
          'flatrate': <dynamic>[],
          'rent': <dynamic>[],
        },
      },
    };

    test('should parse multi-country payload wrapped in results', () {
      final providers = WatchProviders.fromJson(multiCountryJson);

      expect(providers.isNotEmpty, isTrue);
      expect(providers.byCountry.length, equals(3));

      final fr = providers.forCountry('FR');
      expect(fr, isNotNull);
      expect(fr!.link, contains('locale=FR'));
      expect(fr.flatrate.length, equals(2));
      expect(fr.flatrate.first.providerName, equals('Netflix'));
      expect(fr.flatrate.first.logoPath, equals('/netflix.jpg'));
      expect(fr.flatrate.first.providerId, equals(8));
      expect(fr.flatrate.first.displayPriority, equals(0));
      expect(fr.rent.length, equals(1));
      expect(fr.rent.first.providerName, equals('Apple TV'));
      expect(fr.buy.length, equals(1));
      expect(fr.free, isEmpty);

      final us = providers.forCountry('us'); // case-insensitive
      expect(us, isNotNull);
      expect(us!.flatrate.first.providerName, equals('Hulu'));

      final gb = providers.forCountry('GB');
      expect(gb, isNotNull);
      expect(gb!.isEmpty, isTrue);
    });

    test('should parse direct map without results wrapper', () {
      final directMap = Map<String, dynamic>.from(
        multiCountryJson['results'] as Map,
      );
      final providers = WatchProviders.fromJson(directMap);

      expect(providers.forCountry('FR'), isNotNull);
      expect(providers.forCountry('FR')!.flatrate.length, equals(2));
    });

    test('should return null for missing or null country', () {
      final providers = WatchProviders.fromJson(multiCountryJson);

      expect(providers.forCountry('DE'), isNull);
      expect(providers.forCountry(null), isNull);
      expect(providers.forCountry(''), isNull);
    });

    test('should gracefully handle null, empty or invalid json', () {
      expect(WatchProviders.fromJson(null).isEmpty, isTrue);
      expect(WatchProviders.fromJson({}).isEmpty, isTrue);
      expect(
        WatchProviders.fromJson({
          'results': {'FR': 'invalid'},
        }).forCountry('FR'),
        isNull,
      );
    });

    test('should correctly serialize to and from json', () {
      final providers = WatchProviders.fromJson(multiCountryJson);
      final serialized = providers.toJson();
      final roundTrip = WatchProviders.fromJson(serialized);

      expect(roundTrip, equals(providers));
    });

    test(
      'WatchProviderCountryInfo isEmpty is true when all lists are empty',
      () {
        const emptyInfo = WatchProviderCountryInfo(link: 'https://example.com');
        expect(emptyInfo.isEmpty, isTrue);
        expect(emptyInfo.isNotEmpty, isFalse);

        const withOffer = WatchProviderCountryInfo(
          flatrate: [WatchProviderItem(providerId: 1, providerName: 'Test')],
        );
        expect(withOffer.isEmpty, isFalse);
        expect(withOffer.isNotEmpty, isTrue);
      },
    );
  });
}
