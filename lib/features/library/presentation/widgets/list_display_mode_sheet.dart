import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';

/// Shows the display options sheet for a list: Grid 2, 3, 4 columns or Detailed List.
Future<void> showListDisplayModeSheet(
  BuildContext context, {
  required DisplayMode currentMode,
  required int currentGridSize,
  required void Function(DisplayMode mode, int gridSize) onChanged,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (context) => _ListDisplayModeSheetContent(
      currentMode: currentMode,
      currentGridSize: currentGridSize,
      onChanged: onChanged,
    ),
  );
}

class _ListDisplayModeSheetContent extends StatelessWidget {
  const _ListDisplayModeSheetContent({
    required this.currentMode,
    required this.currentGridSize,
    required this.onChanged,
  });

  final DisplayMode currentMode;
  final int currentGridSize;
  final void Function(DisplayMode mode, int gridSize) onChanged;

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

    final isList = currentMode == DisplayMode.list;
    final isGrid = currentMode == DisplayMode.grid;

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
              isSelected: isGrid && currentGridSize == 2,
              onTap: () {
                onChanged(DisplayMode.grid, 2);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayGrid3,
              icon: Icons.grid_view,
              isSelected: isGrid && currentGridSize == 3,
              onTap: () {
                onChanged(DisplayMode.grid, 3);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayGrid4,
              icon: Icons.grid_view,
              isSelected: isGrid && currentGridSize == 4,
              onTap: () {
                onChanged(DisplayMode.grid, 4);
                Navigator.pop(context);
              },
            ),
            _buildOption(
              context: context,
              label: l10n.listsDisplayDetailedList,
              icon: Icons.view_list,
              isSelected: isList,
              onTap: () {
                onChanged(DisplayMode.list, currentGridSize);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
