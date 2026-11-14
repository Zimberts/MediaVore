import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// One chip of a [FilterChipRow].
@immutable
class AppFilterChip {
  const AppFilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Horizontally scrolling row of filter chips.
///
/// Chips are 36 dp pills; the row is [kMinTapTarget] high so that each chip
/// keeps a 48 dp touch area.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.chips,
    this.padding = EdgeInsets.zero,
  });

  final List<AppFilterChip> chips;

  /// Padding of the scrollable content (e.g. the page gutter).
  final EdgeInsetsGeometry padding;

  static const double _chipHeight = 36;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            _Chip(chip: chips[i]),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.chip});

  final AppFilterChip chip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = chip.selected ? colors.onPrimary : colors.text;

    return Material(
      type: MaterialType.transparency,
      child: AppTapTarget(
        onTap: chip.onTap,
        selected: chip.selected,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: FilterChipRow._chipHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: chip.selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: chip.selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chip.icon != null) ...[
                Icon(chip.icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                chip.label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
