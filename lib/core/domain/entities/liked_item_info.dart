import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Information about a liked title with its ID, type, and title.
class LikedItemInfo extends Equatable {
  final int tmdbId;
  final MediaType type;
  final String title;

  const LikedItemInfo({
    required this.tmdbId,
    required this.type,
    required this.title,
  });

  @override
  List<Object?> get props => [tmdbId, type, title];
}
