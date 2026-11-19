import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';

void main() {
  group('PersonSummary', () {
    test('fromJson parses full TMDB search/person result', () {
      final json = {
        'id': 12345,
        'name': 'Denis Villeneuve',
        'profile_path': '/villeneuve.jpg',
        'known_for_department': 'Directing',
        'known_for': [
          {'title': 'Dune'},
          {'name': 'Arrival'},
          {'title': 'Blade Runner 2049'},
        ],
      };

      final person = PersonSummary.fromJson(json);

      expect(person.id, 12345);
      expect(person.name, 'Denis Villeneuve');
      expect(person.profilePath, '/villeneuve.jpg');
      expect(person.knownForDepartment, 'Directing');
      expect(person.knownForTitles, ['Dune', 'Arrival', 'Blade Runner 2049']);
    });

    test('fromJson handles empty or null fields', () {
      final json = <String, dynamic>{};
      final person = PersonSummary.fromJson(json);

      expect(person.id, 0);
      expect(person.name, '');
      expect(person.profilePath, isNull);
      expect(person.knownForDepartment, isNull);
      expect(person.knownForTitles, isEmpty);
    });

    test('toJson and equality', () {
      const person = PersonSummary(
        id: 1,
        name: 'Christopher Nolan',
        profilePath: '/nolan.jpg',
        knownForDepartment: 'Directing',
        knownForTitles: ['Oppenheimer'],
      );

      final map = person.toJson();
      expect(map['id'], 1);
      expect(map['name'], 'Christopher Nolan');
      expect(map['profile_path'], '/nolan.jpg');
      expect(map['known_for_department'], 'Directing');
      expect(map['known_for_titles'], ['Oppenheimer']);

      expect(
        person,
        equals(
          const PersonSummary(
            id: 1,
            name: 'Christopher Nolan',
            profilePath: '/nolan.jpg',
            knownForDepartment: 'Directing',
            knownForTitles: ['Oppenheimer'],
          ),
        ),
      );
    });
  });
}
