import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// Available sort methods for a list of saved items.
enum ListSortMethod { manual, releaseDate, shuffle }

/// Backwards compatibility alias for [ListSortMethod].
typedef SortMethod = ListSortMethod;

/// Shows the sort sheet of the list page (design v1.5).
Future<void> showListSortSheet(
  BuildContext context, {
  required ListSortMethod currentMethod,
  required bool isReversed,
  required ValueChanged<ListSortMethod> onMethodChanged,
  required ValueChanged<bool> onReversedChanged,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (context) => _ListSortSheetContent(
      currentMethod: currentMethod,
      isReversed: isReversed,
      onMethodChanged: onMethodChanged,
      onReversedChanged: onReversedChanged,
    ),
  );
}

class _ListSortSheetContent extends StatefulWidget {
  const _ListSortSheetContent({
    required this.currentMethod,
    required this.isReversed,
    required this.onMethodChanged,
    required this.onReversedChanged,
  });

  final ListSortMethod currentMethod;
  final bool isReversed;
  final ValueChanged<ListSortMethod> onMethodChanged;
  final ValueChanged<bool> onReversedChanged;

  @override
  State<_ListSortSheetContent> createState() => _ListSortSheetContentState();
}

class _ListSortSheetContentState extends State<_ListSortSheetContent> {
  late ListSortMethod _method;
  late bool _reversed;

  @override
  void initState() {
    super.initState();
    _method = widget.currentMethod;
    _reversed = widget.isReversed;
  }

  Widget _buildItem({
    required ListSortMethod method,
    required String label,
    required IconData icon,
    required String subtitle,
  }) {
    final isSelected = _method == method;
    final colors = context.appColors;

    return AppTapTarget(
      onTap: () {
        setState(() => _method = method);
        widget.onMethodChanged(method);
        Navigator.pop(context);
      },
      child: ListTile(
        leading: Icon(icon, color: isSelected ? colors.primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.primary : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colors.text2, fontSize: 12),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: colors.primary)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                l10n.listsSortOptions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
            _buildItem(
              method: ListSortMethod.manual,
              label: l10n.listsSortManual,
              icon: Icons.drag_indicator,
              subtitle: l10n.listsSortManualHint,
            ),
            _buildItem(
              method: ListSortMethod.releaseDate,
              label: l10n.listsSortReleaseDate,
              icon: Icons.calendar_today,
              subtitle: l10n.listsSortReleaseDateHint,
            ),
            _buildItem(
              method: ListSortMethod.shuffle,
              label: l10n.listsSortShuffle,
              icon: Icons.shuffle,
              subtitle: l10n.listsSortShuffleHint,
            ),
            const Divider(height: 16),
            AppTapTarget(
              onTap: () {
                final next = !_reversed;
                setState(() => _reversed = next);
                widget.onReversedChanged(next);
              },
              child: ListTile(
                leading: Icon(
                  _reversed ? Icons.swap_vert_circle : Icons.swap_vert,
                  color: _reversed ? colors.primary : null,
                ),
                title: Text(l10n.listsReverseOrder),
                trailing: Switch(
                  value: _reversed,
                  onChanged: (value) {
                    setState(() => _reversed = value);
                    widget.onReversedChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
