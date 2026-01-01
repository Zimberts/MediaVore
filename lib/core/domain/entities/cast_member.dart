import 'package:equatable/equatable.dart';

class CastMember extends Equatable {
  final String name;
  final String character;
  final String? profilePath;

  const CastMember({
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'],
      character: json['character'],
      profilePath: json['profile_path'],
    );
  }

  @override
  List<Object?> get props => [name, character, profilePath];
}
