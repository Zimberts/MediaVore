import 'package:mediavore/core/domain/entities/media_item.dart';
import 'cast_member.dart';
import 'crew_member.dart';

class MediaDetails {
  final MediaItem item;
  final List<CastMember> cast;
  final CrewMember? director;

  MediaDetails({
    required this.item,
    required this.cast,
    this.director,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'cast': cast.map((c) => c.toJson()).toList(),
      'director': director?.toJson(),
    };
  }

  factory MediaDetails.fromJson(Map<String, dynamic> json) {
    return MediaDetails(
      item: MediaItem.fromJson(json['item']),
      cast: (json['cast'] as List).map((c) => CastMember.fromJson(c)).toList(),
      director: json['director'] != null ? CrewMember.fromJson(json['director']) : null,
    );
  }
}
