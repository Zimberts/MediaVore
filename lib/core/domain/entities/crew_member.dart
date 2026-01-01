import 'package:equatable/equatable.dart';

class CrewMember extends Equatable {
  final String name;
  final String job;

  const CrewMember({
    required this.name,
    required this.job,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      name: json['name'],
      job: json['job'],
    );
  }

  @override
  List<Object?> get props => [name, job];
}
