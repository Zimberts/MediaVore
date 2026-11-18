import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/media_kind.dart';

/// Media type badge: an icon alone, tinted with the color of the type.
///
/// The name of the type ("Movie", "Series", "Book") is never drawn but is
/// exposed to screen readers. [extra] adds a short text next to the icon.
class TypeChip extends StatelessWidget {
  const TypeChip({super.key, required this.kind, this.extra});

  final MediaKind kind;

  /// Optional text shown after the icon (e.g. a count).
  final String? extra;

  /// Side of the icon-only chip.
  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = kind.color(colors);
    final extra = this.extra;
    final label = kind.label(context.l10n);

    return Semantics(
      label: extra == null ? label : '$label, $extra',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: size, minHeight: size),
        padding: extra == null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kind.background(colors),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(kind.icon, size: 13, color: color),
            if (extra != null) ...[
              const SizedBox(width: 5),
              Text(
                extra,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
