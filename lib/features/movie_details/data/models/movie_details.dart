import 'package:mediavore/features/search/data/models/movie.dart';
import 'cast_member.dart';
import 'crew_member.dart';

class MovieDetails {
  final Movie movie;
  final List<CastMember> cast;
  final CrewMember? director;

  MovieDetails({
    required this.movie,
    required this.cast,
    this.director,
  });
}
