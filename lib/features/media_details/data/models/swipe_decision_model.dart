import 'package:isar_community/isar.dart';

part 'swipe_decision_model.g.dart';

@collection
class SwipeDecisionModel {
  Id? isarId;

  @Index()
  final int tmdbId;

  final String mediaType;
  final String title;
  final String? posterPath;

  /// Decision: 'added', 'discarded', or 'seen'.
  final String decision;

  final DateTime decidedAt;
  final String? targetList;
  final int? collectionId;
  final String? collectionName;

  SwipeDecisionModel({
    this.isarId,
    required this.tmdbId,
    this.mediaType = 'movie',
    required this.title,
    this.posterPath,
    required this.decision,
    required this.decidedAt,
    this.targetList,
    this.collectionId,
    this.collectionName,
  });
}
