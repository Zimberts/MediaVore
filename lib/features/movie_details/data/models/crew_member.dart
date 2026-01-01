class CrewMember {
  final String name;
  final String job;

  CrewMember({
    required this.name,
    required this.job,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      name: json['name'],
      job: json['job'],
    );
  }
}
