import 'package:equatable/equatable.dart';

/// Summary of a person (actor, director, etc.) returned by TMDB `/search/person`.
class PersonSummary extends Equatable {
  final int id;
  final String name;
  final String? profilePath;
  final String? knownForDepartment;
  final List<String> knownForTitles;

  const PersonSummary({
    required this.id,
    required this.name,
    this.profilePath,
    this.knownForDepartment,
    this.knownForTitles = const [],
  });

  factory PersonSummary.fromJson(Map<String, dynamic> json) {
    final knownForList = json['known_for'] as List<dynamic>?;
    final titles = <String>[];
    if (knownForList != null) {
      for (final item in knownForList) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] ?? item['name'];
          if (title is String && title.isNotEmpty) {
            titles.add(title);
          }
        }
      }
    }

    return PersonSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      knownForTitles: titles,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profile_path': profilePath,
    'known_for_department': knownForDepartment,
    'known_for_titles': knownForTitles,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    profilePath,
    knownForDepartment,
    knownForTitles,
  ];
}
