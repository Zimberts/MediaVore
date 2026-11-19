import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Displays viewing information on a film detail page:
/// - In simple mode (default): a single summary line
///   « Vu 1 fois · le 3 nov. 2026 » or « Vu 2 fois · dernière fois le 3 nov. 2026 ».
/// - In advanced mode: the "Visionnages" section with each individual viewing
///   (1er, 2e...), editable date and deletable entry with confirmation.
class MediaDetailMovieViewings extends StatelessWidget {
  final MediaItem item;

  const MediaDetailMovieViewings({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.mediaType != MediaType.movie) {
      return const SizedBox.shrink();
    }

    final provider = context.watch<SearchProvider>();
    final settings = Provider.of<SettingsProvider?>(context);
    final advanced = settings?.advancedTracking ?? false;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;

    final viewings = provider.seenItems
        .where((s) => s.tmdbId == item.id && s.type == MediaType.movie)
        .toList();

    if (viewings.isEmpty) {
      return const SizedBox.shrink();
    }

    viewings.sort((a, b) => a.seenDate.compareTo(b.seenDate));

    if (!advanced) {
      final lastViewing = viewings.last;
      final dateStr = Formatters.formatSeenDate(
        lastViewing.seenDate,
        l10n.localeName,
      );
      final summaryText = viewings.length == 1
          ? l10n.seenSummaryOnce(dateStr)
          : l10n.seenSummaryMultiple(viewings.length, dateStr);

      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Text(
          summaryText,
          key: const Key('movie_seen_summary'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.text2,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        key: const Key('movie_visionnages_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seenVisionnagesSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < viewings.length; i++) ...[
            _MovieViewingTile(
              item: item,
              seenEntry: viewings[i],
              ordinal: l10n.seenOrdinal((i + 1).toString()),
            ),
            if (i < viewings.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _MovieViewingTile extends StatelessWidget {
  final MediaItem item;
  final SeenItem seenEntry;
  final String ordinal;

  const _MovieViewingTile({
    required this.item,
    required this.seenEntry,
    required this.ordinal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final provider = context.read<SearchProvider>();
    final dateStr = Formatters.formatSeenDateTime(
      seenEntry.seenDate,
      l10n.localeName,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.history, color: colors.primary),
      title: Text('$ordinal · $dateStr'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.seenEditViewing,
            onPressed: () async {
              final result = await showSeenDateTimePickerDialog(
                context,
                item: item,
                initialDate: seenEntry.seenDate,
                isEditing: true,
              );
              if (result != null) {
                await provider.updateSeenEntry(
                  seenEntry.copyWith(seenDate: result.date),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.error),
            tooltip: l10n.commonDelete,
            onPressed: () async {
              final confirmed = await showAppDialog<bool>(
                context: context,
                title: l10n.seenRemoveLogTitle,
                message: l10n.seenRemoveLogMessage,
                actions: [
                  AppDialogAction(
                    label: l10n.commonCancel,
                    value: false,
                  ),
                  AppDialogAction(
                    label: l10n.commonDelete,
                    value: true,
                    danger: true,
                  ),
                ],
              );
              if (confirmed == true && seenEntry.id != null) {
                await provider.deleteSeenEntry(seenEntry.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
