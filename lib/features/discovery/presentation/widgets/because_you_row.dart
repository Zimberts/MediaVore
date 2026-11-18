import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/because_you_data.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/watchlist_icon_button.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/widgets/media_item_poster.dart';
import 'package:provider/provider.dart';

/// Horizontal carousel displaying personalized recommendations in Discover Explore mode.
class BecauseYouRow extends StatelessWidget {
  final BecauseYouData data;
  final ValueChanged<MediaItem>? onOpen;

  const BecauseYouRow({super.key, required this.data, this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (data.items.length < 3) return const SizedBox.shrink();

    final l10n = context.l10n;
    final title = data.reason == BecauseYouReason.liked
        ? l10n.discoverBecauseYouLiked(data.sourceTitle)
        : l10n.discoverBecauseYouWatched(data.sourceTitle);

    final provider = context.watch<SearchProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;

    return Column(
      key: const Key('discovery_because_you_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          key: const Key('discovery_because_you_header'),
          title: title,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160 + 40 * textScale,
          child: ListView.builder(
            key: const Key('discovery_because_you_list'),
            scrollDirection: Axis.horizontal,
            itemCount: data.items.length,
            itemBuilder: (context, index) {
              final item = data.items[index];
              return Container(
                width: 110,
                margin: const EdgeInsetsDirectional.only(end: 12),
                child: MediaPosterCard(
                  key: ValueKey('because_you_card_${item.id}'),
                  data: mediaItemPosterData(
                    context,
                    item,
                    seenCount: provider.getSeenCount(item),
                    liked: provider.isLiked(item),
                  ),
                  onTap: () => onOpen != null
                      ? onOpen!(item)
                      : MediaDetailPage.show(context, item),
                  action: WatchlistIconButton(
                    item: item,
                    iconSize: 18,
                    onImage: true,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
