import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// Title of a section with an optional link on the right ("See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel,
  });

  final String title;

  /// Shows the link when given.
  final VoidCallback? onAction;

  /// Text of the link; "See all" by default.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return ConstrainedBox(
      // Same height with or without the link, so sections stay aligned.
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ),
          ),
          if (onAction != null)
            Material(
              type: MaterialType.transparency,
              child: AppTapTarget(
                onTap: onAction,
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  actionLabel ?? context.l10n.commonSeeAll,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    color: colors.text,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
