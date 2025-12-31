import 'package:equatable/equatable.dart';

class Movie extends Equatable {
  final int id;
  final String title;
  final String? posterPath;
  final String overview;
  final String releaseDate;

  const Movie({
    required this.id,
    required this.title,
    this.posterPath,
    required this.overview,
    required this.releaseDate,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      posterPath: json['poster_path'],
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'overview': overview,
      'release_date': releaseDate,
    };
  }

  @override
  List<Object?> get props => [id, title, posterPath, overview, releaseDate];
}
