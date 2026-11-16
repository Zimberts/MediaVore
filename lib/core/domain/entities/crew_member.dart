import 'package:equatable/equatable.dart';

class CrewMember extends Equatable {
  final int? id;
  final String name;
  final String job;
  final String? profilePath;

  const CrewMember({
    this.id,
    required this.name,
    required this.job,
    this.profilePath,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] as String?) ?? '',
      job: (json['job'] as String?) ?? '',
      profilePath: json['profile_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'job': job,
      if (profilePath != null) 'profile_path': profilePath,
    };
  }

  @override
  List<Object?> get props => [id, name, job, profilePath];
}
