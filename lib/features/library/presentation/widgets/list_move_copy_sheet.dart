import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/library/presentation/widgets/list_dialogs.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';

/// Result of [showListMoveCopySheet]: target list name and whether to keep the
/// items in the source list (copy) instead of removing them (move).
typedef ListMoveCopyResult = ({String targetList, bool keepSource});

/// Opens a bottom sheet letting the user choose whether to move or copy the
/// current selection to another list (excluding [currentList]), or create a
/// new list on the fly.
Future<ListMoveCopyResult?> showListMoveCopySheet(
  BuildContext context, {
  required String currentList,
  required List<String> listNames,
}) {
  final otherLists = listNames.where((name) => name != currentList).toList();
  return showAppSheet<ListMoveCopyResult>(
    context: context,
    builder: (context) => _ListMoveCopySheetContent(otherLists: otherLists),
  );
}

class _ListMoveCopySheetContent extends StatefulWidget {
  const _ListMoveCopySheetContent({required this.otherLists});

  final List<String> otherLists;

  @override
  State<_ListMoveCopySheetContent> createState() =>
      _ListMoveCopySheetContentState();
}

class _ListMoveCopySheetContentState extends State<_ListMoveCopySheetContent> {
  bool _keepSource = false;

  Future<void> _onCreateNewList() async {
    final created = await showCreateListDialog(context);
    if (created != null && mounted) {
      Navigator.pop<ListMoveCopyResult>(context, (
        targetList: created,
        keepSource: _keepSource,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listsMoveOrCopyTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              label: Text(l10n.listsActionMove),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(l10n.listsActionCopy),
            ),
          ],
          selected: {_keepSource},
          onSelectionChanged: (selection) {
            setState(() => _keepSource = selection.first);
          },
        ),
        const SizedBox(height: 8),
        for (final name in widget.otherLists)
          AppTapTarget(
            onTap: () => Navigator.pop<ListMoveCopyResult>(context, (
              targetList: name,
              keepSource: _keepSource,
            )),
            child: ListTile(
              leading: Icon(
                name == kWatchlistName
                    ? Icons.bookmark_outline
                    : Icons.list_alt,
              ),
              title: Text(listDisplayName(l10n, name)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (widget.otherLists.isNotEmpty) const Divider(height: 16),
        AppTapTarget(
          onTap: _onCreateNewList,
          child: ListTile(
            leading: Icon(Icons.add, color: colors.primary),
            title: Text(
              l10n.listsCreateNew,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
