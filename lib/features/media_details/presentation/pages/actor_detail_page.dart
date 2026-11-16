import 'package:flutter/material.dart';
import 'package:mediavore/features/media_details/presentation/pages/person_page.dart';

export 'person_page.dart';

class ActorDetailPage extends PersonPage {
  const ActorDetailPage({
    super.key,
    required int actorId,
    required String actorName,
    super.isSheet,
    super.scrollController,
  }) : super(personId: actorId, personName: actorName);

  static Future<void> show(
    BuildContext context, {
    required int actorId,
    required String actorName,
  }) => PersonPage.show(context, personId: actorId, personName: actorName);
}
