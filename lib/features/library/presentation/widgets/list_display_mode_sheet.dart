import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

/// Shows the display options sheet for a list: Grid 2, 3, 4 columns, Detailed List,
/// and whether to stack movies of the same saga.
Future<void> showListDisplayModeSheet(
  BuildContext context, {
  required DisplayMode currentMode,
  required int currentGridSize,
  required void Function(DisplayMode mode, int gridSize) onChanged,
  bool stackSagas = true,
  ValueChanged<bool>? onStackSagasChanged,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (context) => _ListDisplayModeSheetContent(
      currentMode: currentMode,
      currentGridSize: currentGridSize,
      onChanged: onChanged,
      stackSagas: stackSagas,
      onStackSagasChanged: onStackSagasChanged,
    ),
  );
}

class _ListDisplayModeSheetContent extends StatefulWidget {
  const _ListDisplayModeSheetContent({
    required this.currentMode,
    required this.currentGridSize,
    required this.onChanged,
    required this.stackSagas,
    this.onStackSagasChanged,
  });

  final DisplayMode currentMode;
  final int currentGridSize;
  final void Function(DisplayMode mode, int gridSize) onChanged;
  final bool stackSagas;
  final ValueChanged<bool>? onStackSagasChanged;

  @override
  State<_ListDisplayModeSheetContent> createState() =>
      _ListDisplayModeSheetContentState();
}

class _ListDisplayModeSheetContentState
    extends State<_ListDisplayModeSheetContent> {
  late bool _stackSagas = widget.stackSagas;

  Widget _buildOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return AppTapTarget(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? colors.primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.primary : null,
          ),
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

    final isList = widget.currentMode == DisplayMode.list;
    final isGrid = widget.currentMode == DisplayMode.grid;

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
                l10n.listsDisplayOptions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayGrid2,
              icon: Icons.grid_view,
              isSelected: isGrid && widget.currentGridSize == 2,
              onTap: () {
                widget.onChanged(DisplayMode.grid, 2);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayGrid3,
              icon: Icons.grid_view,
              isSelected: isGrid && widget.currentGridSize == 3,
              onTap: () {
                widget.onChanged(DisplayMode.grid, 3);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayGrid4,
              icon: Icons.grid_view,
              isSelected: isGrid && widget.currentGridSize == 4,
              onTap: () {
                widget.onChanged(DisplayMode.grid, 4);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayDetailedList,
              icon: Icons.view_list,
              isSelected: isList,
              onTap: () {
                widget.onChanged(DisplayMode.list, widget.currentGridSize);
                Navigator.pop(context);
              },
            ),
            if (widget.onStackSagasChanged != null) ...[
              const Divider(height: 16),
              SwitchListTile(
                key: const Key('list_display_stack_sagas'),
                secondary: const Icon(Icons.collections_bookmark_outlined),
                title: Text(l10n.listsStackSagas),
                subtitle: Text(l10n.listsStackSagasHint),
                value: _stackSagas,
                onChanged: (value) {
                  setState(() => _stackSagas = value);
                  widget.onStackSagasChanged!(value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
