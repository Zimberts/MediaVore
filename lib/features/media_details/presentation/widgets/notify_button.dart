import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class NotifyButton extends StatelessWidget {
  final MediaItem item;

  const NotifyButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        final isNotified = provider.isNotified(item);
        
        // Only show if not released or if it's a TV show (could have new episodes)
        bool shouldShow = false;
        if (item.mediaType == MediaType.tv) {
          shouldShow = item.status != 'Ended' && item.status != 'Canceled';
        } else if (item.mediaType == MediaType.movie) {
          if (item.releaseDate.isEmpty) {
            shouldShow = true;
          } else {
            try {
              final releaseDate = DateTime.parse(item.releaseDate);
              shouldShow = releaseDate.isAfter(DateTime.now());
            } catch (_) {
              shouldShow = true;
            }
          }
        }

        if (!shouldShow && !isNotified) return const SizedBox.shrink();

        return IconButton(
          icon: Icon(
            isNotified ? Icons.notifications_active : Icons.notifications_none,
            color: isNotified ? Colors.orange : null,
          ),
          onPressed: () => provider.toggleNotification(item),
          tooltip: isNotified ? 'Disable notifications' : 'Notify me on release',
        );
      },
    );
  }
}
