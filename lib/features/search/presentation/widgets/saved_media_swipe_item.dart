import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/like_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/poster_with_badge.dart';

class MediaSwipeItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final VoidCallback onReturn;

  const MediaSwipeItem({
    super.key,
    required this.item,
    required this.provider,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  await MediaDetailPage.show(context, item);
                  onReturn();
                },
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: PosterWithBadge(
                    item: item,
                    provider: provider,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const SizedBox(width: 56), // Balances the larger LikeButton
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await MediaDetailPage.show(context, item);
                        onReturn();
                      },
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  LikeButton(item: item, iconSize: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
