import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// Grid of visual swatch cards for selecting a theme palette of one brightness.
class PalettePickerGrid extends StatelessWidget {
  const PalettePickerGrid({
    super.key,
    required this.label,
    required this.gridKey,
    required this.selected,
    required this.palettes,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final Key gridKey;
  final AppPaletteId selected;
  final List<AppPalette> palettes;
  final ValueChanged<AppPaletteId> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final l10n = context.l10n;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: !enabled,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  const maxExtent = 140.0;
                  final columns = (constraints.maxWidth / (maxExtent + spacing))
                      .ceil()
                      .clamp(2, 6);
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  final itemHeight = (itemWidth / 1.35).clamp(56.0, 92.0);
                  return Wrap(
                    key: gridKey,
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final palette in palettes)
                        SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: PaletteSwatchCard(
                            key: Key('settings_palette_${palette.id.name}'),
                            palette: palette,
                            name: paletteName(l10n, palette.id),
                            selected: palette.id == selected,
                            onTap: () => onChanged(palette.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual preview card of an [AppPalette] showing its background, surface, and
/// accent colors.
class PaletteSwatchCard extends StatelessWidget {
  const PaletteSwatchCard({
    super.key,
    required this.palette,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(
        color: selected ? palette.primary : palette.border,
        width: selected ? 2.5 : 1,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: palette.bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border, width: 0.75),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: palette.surface2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            color: palette.text,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: palette.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
