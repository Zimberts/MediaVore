import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Library tab: the former Lists and History pages behind a segment, until
/// the Library epic replaces their content.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final section = context.select<SearchProvider, LibrarySection>(
      (provider) => provider.librarySection,
    );

    return ColoredBox(
      color: context.appColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            Expanded(
              // Both pages stay alive so each keeps its state.
              child: IndexedStack(
                index: section.index,
                children: const [SavedMediaPage(), SeenHistoryPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
