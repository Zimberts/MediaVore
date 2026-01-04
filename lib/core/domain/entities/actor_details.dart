import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

class ActorDetails extends Equatable {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? profilePath;
  final List<MediaItem> items;

  const ActorDetails({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.profilePath,
    this.items = const [],
  });

  factory ActorDetails.fromJson(Map<String, dynamic> json, {List<MediaItem> items = const []}) {
    return ActorDetails(
      id: json['id'],
      name: json['name'],
      biography: json['biography'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
      profilePath: json['profile_path'],
      items: items,
    );
  }

  @override
  List<Object?> get props => [id, name, biography, birthday, placeOfBirth, profilePath, items];
}
