import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// One choice of an [AppSegmented].
@immutable
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented control of the design: a tinted track holding equal-width
/// segments, the selected one raised on a surface pill.
///
/// The track is 44 dp high (36 dp segments); the touch area of each segment
/// is extended to [kMinTapTarget].
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.accent,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Text color of the selected segment; the ink by default.
  final Color? accent;

  static const double _segmentHeight = 36;
  static const double _trackPadding = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical:
                    (kMinTapTarget - _segmentHeight - 2 * _trackPadding) / 2,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _trackPadding),
            child: Row(
              children: [
                for (final segment in segments)
                  Expanded(
                    child: _Segment(
                      label: segment.label,
                      icon: segment.icon,
                      selected: segment.value == selected,
                      onTap: () => onChanged(segment.value),
                      selectedColor: accent ?? colors.text,
                      style: textTheme.labelLarge,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.style,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = selected ? selectedColor : colors.text2;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Center(
            heightFactor: 1,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSegmented._segmentHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: selected
                  ? BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Align(
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style?.copyWith(
                          fontSize: 13,
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
