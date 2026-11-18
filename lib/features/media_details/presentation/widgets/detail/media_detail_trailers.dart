import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/media_poster_card.dart';
import 'package:mediavore/core/widgets/section_header.dart';

/// "Trailers" section: YouTube trailers of the title. Draws nothing when
/// there is none.
class MediaDetailTrailers extends StatelessWidget {
  const MediaDetailTrailers({
    super.key,
    required this.videos,
    required this.onOpen,
  });

  /// TMDB `videos` entries.
  final List<Map<String, dynamic>>? videos;

  /// Called with the YouTube link of the tapped trailer.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final trailers = (videos ?? const <Map<String, dynamic>>[])
        .where((v) => v['type'] == 'Trailer' && v['site'] == 'YouTube')
        .toList();
    if (trailers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.detailTrailers),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trailers.length,
            itemBuilder: (context, index) {
              final key = trailers[index]['key'];
              final name = trailers[index]['name'];
              return Semantics(
                button: true,
                label: name is String ? name : context.l10n.detailTrailers,
                child: GestureDetector(
                  onTap: () => onOpen('https://www.youtube.com/watch?v=$key'),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: MediaPosterCard.badgeBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: 'https://img.youtube.com/vi/$key/0.jpg',
                            fit: BoxFit.cover,
                            width: 160,
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill,
                          color: MediaPosterCard.onImage,
                          size: 40,
                        ),
                      ],
                    ),
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
