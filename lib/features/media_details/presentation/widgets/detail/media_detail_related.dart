import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';

/// Horizontal row of related titles ("Similar", "Recommendations"). Draws
/// nothing when [items] is empty.
class MediaDetailRelated extends StatelessWidget {
  const MediaDetailRelated({
    super.key,
    required this.title,
    required this.items,
    required this.onOpen,
  });

  final String title;
  final List<MediaItem>? items;
  final ValueChanged<MediaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = this.items;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 126 + 22 * textScale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final icon = Icon(
                item.mediaType == MediaType.tv ? Icons.tv : Icons.movie,
              );
              return GestureDetector(
                onTap: () => onOpen(item),
                child: Container(
                  width: 100,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185${item.posterPath}',
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: colors.placeholder),
                                errorWidget: (context, url, error) => icon,
                              )
                            : Container(
                                height: 120,
                                color: colors.placeholder,
                                child: icon,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
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
