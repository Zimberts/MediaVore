import 'package:equatable/equatable.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';

/// Reason why a recommendation is shown.
enum BecauseYouReason { liked, watched }

/// Recommendation data for the "Because you..." section in Discover.
class BecauseYouData extends Equatable {
  final int sourceId;
  final MediaType sourceType;
  final String sourceTitle;
  final BecauseYouReason reason;
  final List<MediaItem> items;

  const BecauseYouData({
    required this.sourceId,
    required this.sourceType,
    required this.sourceTitle,
    required this.reason,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'sourceType': sourceType.name,
    'sourceTitle': sourceTitle,
    'reason': reason.name,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory BecauseYouData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return BecauseYouData(
      sourceId: json['sourceId'] as int,
      sourceType: MediaType.values.byName(json['sourceType'] as String),
      sourceTitle: json['sourceTitle'] as String,
      reason: BecauseYouReason.values.byName(json['reason'] as String),
      items: rawItems
          .map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [sourceId, sourceType, sourceTitle, reason, items];
}
