import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/features/home/presentation/upcoming_actions.dart';
import 'package:mediavore/features/home/presentation/widgets/upcoming_row.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Card of releases, one [UpcomingRow] each, wired to the actions of a
/// release: open, mark as seen, menu.
class UpcomingRowsCard extends StatefulWidget {
  const UpcomingRowsCard({super.key, required this.items, required this.now});

  final List<NotifiedItem> items;
  final DateTime now;

  @override
  State<UpcomingRowsCard> createState() => _UpcomingRowsCardState();
}

class _UpcomingRowsCardState extends State<UpcomingRowsCard> {
  /// Releases being marked as seen.
  final Set<String> _marking = {};

  static String _id(NotifiedItem item) =>
      '${item.type.name}_${item.tmdbId}_${item.seasonNumber}_'
      '${item.episodeNumber}';

  Future<void> _markSeen(NotifiedItem item) async {
    if (!_marking.add(_id(item))) return;
    setState(() {});
    try {
      await markReleaseSeen(context, item);
    } finally {
      _marking.remove(_id(item));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = widget.items;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            UpcomingRow(
              key: ValueKey('upcoming_row_${_id(items[i])}'),
              item: items[i],
              now: widget.now,
              onOpen: () => openRelease(context, items[i]),
              onMarkSeen: _marking.contains(_id(items[i]))
                  ? null
                  : () => _markSeen(items[i]),
              onMenu: () => showReleaseMenu(context, items[i]),
            ),
          ],
        ],
      ),
    );
  }
}
