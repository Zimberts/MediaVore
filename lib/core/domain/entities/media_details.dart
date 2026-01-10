import 'package:mediavore/core/domain/entities/media_item.dart';
import 'cast_member.dart';
import 'crew_member.dart';

class MediaDetails {
  final MediaItem item;
  final List<CastMember> cast;
  final CrewMember? director;
  final List<MediaItem>? similar;
  final List<MediaItem>? recommendations;
  final Map<String, dynamic>? watchProviders;
  final List<Map<String, dynamic>>? videos;

  MediaDetails({
    required this.item,
    required this.cast,
    this.director,
    this.similar,
    this.recommendations,
    this.watchProviders,
    this.videos,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'cast': cast.map((c) => c.toJson()).toList(),
      'director': director?.toJson(),
      'similar': similar?.map((i) => i.toJson()).toList(),
      'recommendations': recommendations?.map((i) => i.toJson()).toList(),
      'watch_providers': watchProviders,
      'videos': videos,
    };
  }

  factory MediaDetails.fromJson(Map<String, dynamic> json) {
    return MediaDetails(
      item: MediaItem.fromJson(json['item']),
      cast: (json['cast'] as List).map((c) => CastMember.fromJson(c)).toList(),
      director: json['director'] != null ? CrewMember.fromJson(json['director']) : null,
      similar: json['similar'] != null 
          ? (json['similar'] as List).map((i) => MediaItem.fromJson(i)).toList() 
          : null,
      recommendations: json['recommendations'] != null 
          ? (json['recommendations'] as List).map((i) => MediaItem.fromJson(i)).toList() 
          : null,
      watchProviders: json['watch_providers'],
      videos: json['videos'] != null 
          ? (json['videos'] as List).map((v) => Map<String, dynamic>.from(v)).toList() 
          : null,
    );
  }
}
