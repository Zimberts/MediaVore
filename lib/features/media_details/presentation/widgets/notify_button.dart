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
        final shouldShow = item.canBeNotified;

        if (!shouldShow && !isNotified) return const SizedBox.shrink();

        return IconButton(
          icon: Icon(
            isNotified ? Icons.notifications_active : Icons.notifications_none,
            color: isNotified ? Colors.orange : null,
          ),
          onPressed: () => provider.toggleNotification(item),
          tooltip: isNotified
              ? 'Disable notifications'
              : 'Notify me on release',
        );
      },
    );
  }
}
