import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';

class MediaDetails {
  final MediaItem item;
  final List<CastMember> cast;
  final CrewMember? director;

  MediaDetails({required this.item, required this.cast, this.director});
}
