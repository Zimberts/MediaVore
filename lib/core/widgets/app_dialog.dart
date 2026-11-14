import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// One button of a [showAppDialog]; tapping it closes the dialog with
/// [value].
@immutable
class AppDialogAction<T> {
  const AppDialogAction({required this.label, this.value, this.danger = false});

  final String label;
  final T? value;

  /// Destructive action, drawn in the danger color.
  final bool danger;
}

/// One row of a [showAppMenu]; tapping it closes the menu with [value].
@immutable
class AppMenuItem<T> {
  const AppMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
    this.danger = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;

  /// Destructive action, drawn in the danger color.
  final bool danger;
}

/// Opens the dialog of the design and completes with the value of the tapped
/// action (`null` when dismissed).
///
/// Without [actions] the dialog only has a "Close" button.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  String? message,
  Widget? content,
  List<AppDialogAction<T>> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => _AppDialog<T>(
      title: title,
      subtitle: subtitle,
      actions: actions,
      children: [
        if (message != null)
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ?content,
      ],
    ),
  );
}

/// Opens a menu of actions as a dialog and completes with the value of the
/// tapped row (`null` when closed). Run the action once the future completes.
Future<T?> showAppMenu<T>({
  required BuildContext context,
  required String title,
  required List<AppMenuItem<T>> items,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => _AppDialog<T>(
      title: title,
      actions: const [],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [for (final item in items) _MenuRow<T>(item: item)],
        ),
      ],
    ),
  );
}

class _AppDialog<T> extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.actions,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<AppDialogAction<T>> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                namesRoute: true,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(color: colors.text2),
                ),
              for (final child in children) ...[
                const SizedBox(height: 14),
                child,
              ],
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (actions.isEmpty)
                      _DialogButton(
                        label: context.l10n.commonClose,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    for (final action in actions)
                      _DialogButton(
                        label: action.label,
                        danger: action.danger,
                        onPressed: () =>
                            Navigator.of(context).pop<T>(action.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: danger ? colors.danger : colors.text,
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Text(label),
    );
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.item});

  final AppMenuItem<T> item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final color = item.danger ? colors.danger : colors.text;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop<T>(item.value),
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 20, color: color),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.text2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
