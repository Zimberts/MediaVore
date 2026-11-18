import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/utils/release_sort.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/core/widgets/type_chip.dart';
import 'package:mediavore/features/home/presentation/home_formatters.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Row of a release in "Upcoming": date badge (a clock without a date),
/// title, what is released, the button that marks a release already out as
/// seen and the menu.
class UpcomingRow extends StatelessWidget {
  const UpcomingRow({
    super.key,
    required this.item,
    required this.now,
    required this.onOpen,
    required this.onMarkSeen,
    required this.onMenu,
  });

  final NotifiedItem item;
  final DateTime now;

  /// Opens the title.
  final VoidCallback onOpen;

  /// Marks the release as seen; only offered once it is out. `null` while it
  /// is being marked.
  final VoidCallback? onMarkSeen;

  /// Opens the menu of the release.
  final VoidCallback onMenu;

  /// Out today or earlier: it can be marked as seen.
  static bool isReleased(NotifiedItem item, DateTime now) {
    final date = item.releaseDate;
    return date != null && !date.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final kind = MediaKind.fromMediaType(item.type);
    final date = item.releaseDate?.toLocal();
    final released = isReleased(item, now);
    final season = item.seasonNumber;
    final episode = item.episodeNumber;
    final runtime = Formatters.formatRuntime(item.runtime);
    final subtitle = [
      if (item.type == MediaType.tv && season != null && episode != null)
        l10n.homeEpisodeCode(season, episode),
      if (date != null)
        l10n.notifReleaseDate('$released', formatMediumDate(l10n, date))
      else
        releaseSubtitleForItem(item, l10n),
      if (runtime.isNotEmpty) runtime,
    ].join(' · ');

    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(
              child: InkWell(
                onTap: onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: kMinTapTarget),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      10,
                      8,
                      10,
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: _DateBadge(
                            date: date,
                            kind: kind,
                            month: date == null
                                ? null
                                : formatShortMonth(l10n, date),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  TypeChip(kind: kind),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(subtitle, style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (released)
            IconButton(
              constraints: const BoxConstraints(
                minWidth: kMinTapTarget,
                minHeight: kMinTapTarget,
              ),
              tooltip: l10n.upcomingMarkSeen(item.title),
              onPressed: onMarkSeen,
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.stateOutline),
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(Icons.check, size: 20, color: colors.text),
                ),
              ),
            ),
          IconButton(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            tooltip: l10n.inProgressMoreActions(item.title),
            onPressed: onMenu,
            icon: Icon(Icons.more_vert, size: 20, color: colors.text2),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.date,
    required this.kind,
    required this.month,
  });

  final DateTime? date;
  final MediaKind kind;
  final String? month;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final date = this.date;
    final color = date == null ? colors.text2 : kind.color(colors);

    return Container(
      width: _size,
      constraints: const BoxConstraints(minHeight: _size),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: date == null ? colors.surface2 : kind.background(colors),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: date == null
          ? Icon(Icons.schedule, size: 18, color: color)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  month ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ),
    );
  }
}
