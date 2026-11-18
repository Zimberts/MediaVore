import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// Bordered card of the design: surface fill, hairline border, no shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  /// Label of the card for screen readers when it is tappable.
  final String? semanticLabel;

  static const double radius = 18;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: colors.border),
    );
    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (onTap != null) {
      content = Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            child: content,
          ),
        ),
      );
    }

    return Material(
      color: colors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
