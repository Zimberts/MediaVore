import 'package:flutter/material.dart';

/// Smallest side of the touch area of any interactive element (design v1.5).
const double kMinTapTarget = 48;

/// Makes [child] tappable with a touch area of at least [kMinTapTarget] in
/// both directions, whatever the size of the visual itself (a 36 dp chip, a
/// text link, a 40 dp check box...). The visual stays centered in the area.
///
/// Needs a [Material] ancestor for the ink.
class AppTapTarget extends StatelessWidget {
  const AppTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.selected,
    this.tooltip,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;

  /// `null` disables the target.
  final VoidCallback? onTap;

  /// Replaces the semantics of [child] when given.
  final String? semanticLabel;

  /// Selected state announced by screen readers (chips, segments).
  final bool? selected;

  final String? tooltip;

  /// Shape of the ink feedback.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget result = Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: semanticLabel,
      // With a label the children are excluded: re-expose the tap.
      onTap: semanticLabel != null ? onTap : null,
      excludeSemantics: semanticLabel != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTapTarget,
            minHeight: kMinTapTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
    if (tooltip != null) {
      result = Tooltip(message: tooltip, child: result);
    }
    return result;
  }
}
