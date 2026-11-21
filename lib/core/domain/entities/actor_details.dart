import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

typedef PersonDetails = ActorDetails;

class ActorDetails extends Equatable {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? profilePath;

  /// Filmography as an actor/actress (`cast` in TMDB).
  final List<MediaItem> items;

  /// Filmography as a director or creator (`crew` in TMDB).
  final List<MediaItem> crewItems;

  const ActorDetails({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.profilePath,
    this.items = const [],
    this.crewItems = const [],
  });

  factory ActorDetails.fromJson(
    Map<String, dynamic> json, {
    List<MediaItem> items = const [],
    List<MediaItem> crewItems = const [],
  }) {
    return ActorDetails(
      id: json['id'] as int,
      name: json['name'] as String,
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      profilePath: json['profile_path'] as String?,
      items: items,
      crewItems: crewItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (biography != null) 'biography': biography,
      if (birthday != null) 'birthday': birthday,
      if (placeOfBirth != null) 'place_of_birth': placeOfBirth,
      if (profilePath != null) 'profile_path': profilePath,
      'items': items.map((i) => i.toJson()).toList(),
      'crew_items': crewItems.map((i) => i.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    biography,
    birthday,
    placeOfBirth,
    profilePath,
    items,
    crewItems,
  ];
}
