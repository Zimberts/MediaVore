import 'package:flutter/material.dart';

/// Placeholder shown when a screen has nothing to display.
///
/// Shows an [icon], a [title], an optional help [message] and, when both
/// [actionLabel] and [onAction] are given, a button leading to the action
/// that fills the screen (e.g. searching for a movie).
///
/// Sizes itself to its content and centers it, so it works both as a page
/// body and inside a scrollable (e.g. under a `RefreshIndicator`).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = actionLabel;
    final action = onAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (label != null && action != null) ...[
              const SizedBox(height: 24),
              actionIcon != null
                  ? FilledButton.icon(
                      onPressed: action,
                      icon: Icon(actionIcon),
                      label: Text(label),
                    )
                  : FilledButton(onPressed: action, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
