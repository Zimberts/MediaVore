import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/core/widgets/filter_chip_row.dart';
import 'package:mediavore/core/widgets/media_kind.dart';
import 'package:mediavore/features/library/presentation/widgets/list_dialogs.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Library tab: Lists and History behind a segment, with a media type filter
/// shared by both.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.scannerBuilder});

  /// Replaces the camera of the QR import (tests).
  final ListScannerBuilder? scannerBuilder;

  /// Media types offered by the filter. Books join with the books epic.
  static const List<MediaType> filterTypes = [MediaType.movie, MediaType.tv];

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  /// `null` shows every type.
  MediaType? _type;

  void _openList(String name) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedMediaPage(initialList: name, typeFilter: _type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<SearchProvider>();
    final section = provider.librarySection;

    String chipLabel(String label, MediaType? type) =>
        l10n.libraryTypeChip(label, provider.countListEntries(type));

    return ColoredBox(
      color: context.appColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.navLibrary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppSegmented<LibrarySection>(
                segments: [
                  AppSegment(
                    value: LibrarySection.lists,
                    label: l10n.librarySectionLists,
                  ),
                  AppSegment(
                    value: LibrarySection.history,
                    label: l10n.navHistory,
                  ),
                ],
                selected: section,
                onChanged: context.read<SearchProvider>().setLibrarySection,
              ),
            ),
            const SizedBox(height: 4),
            FilterChipRow(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              chips: [
                AppFilterChip(
                  label: chipLabel(l10n.libraryTypeAll, null),
                  selected: _type == null,
                  onTap: () => setState(() => _type = null),
                ),
                for (final type in LibraryPage.filterTypes)
                  AppFilterChip(
                    label: chipLabel(
                      type == MediaType.tv
                          ? l10n.commonTvShows
                          : l10n.commonMovies,
                      type,
                    ),
                    icon: MediaKind.fromMediaType(type).icon,
                    selected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            Expanded(
              // Both sections stay alive so each keeps its state.
              child: IndexedStack(
                index: section.index,
                children: [
                  ListsOverview(
                    type: _type,
                    onOpenList: _openList,
                    scannerBuilder: widget.scannerBuilder,
                  ),
                  SeenHistoryPage(typeFilter: _type, externalTypeFilter: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
