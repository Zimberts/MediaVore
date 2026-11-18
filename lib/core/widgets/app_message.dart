import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';

/// Feedback message shown by [showAppMessage].
@immutable
class AppMessage {
  const AppMessage({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasAction => actionLabel != null && onAction != null;

  /// 6 s when the message offers an action (e.g. "Undo"), 2.5 s otherwise.
  Duration get duration => hasAction
      ? AppMessageHost.durationWithAction
      : AppMessageHost.durationWithoutAction;
}

/// Holds the message currently shown by the [AppMessageHost] of the app.
class AppMessageController extends ChangeNotifier {
  AppMessage? _current;

  AppMessage? get current => _current;

  /// Shows [message], replacing the one on screen. Ignored while no
  /// [AppMessageHost] is mounted (nothing could display it).
  void show(AppMessage message) {
    if (!hasListeners) {
      debugPrint('AppMessage dropped, no AppMessageHost: ${message.text}');
      return;
    }
    _current = message;
    notifyListeners();
  }

  void dismiss() {
    if (_current == null) return;
    _current = null;
    notifyListeners();
  }

  /// Forgets the message once the last host is gone, so that a host mounted
  /// later does not show a stale one.
  void _clearIfUnattached() {
    if (!hasListeners) _current = null;
  }
}

/// Controller of the single message area of the app.
final AppMessageController appMessageController = AppMessageController();

/// Unified feedback of an action: a message at the bottom of the screen,
/// above the tab bar and above any pushed page, sheet or dialog.
///
/// With [actionLabel] and [onAction] (typically "Undo") the message stays
/// 6 s, otherwise 2.5 s. Every reversible action of the app reports through
/// this function. Needs an [AppMessageHost] above the navigator.
void showAppMessage(
  String text, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  appMessageController.show(
    AppMessage(text: text, actionLabel: actionLabel, onAction: onAction),
  );
}

/// Displays the messages of [showAppMessage] on top of [child].
///
/// Insert it in `MaterialApp.builder` so that it sits above the navigator:
/// messages then stay visible over pushed pages, sheets and dialogs.
class AppMessageHost extends StatefulWidget {
  const AppMessageHost({
    super.key,
    required this.child,
    this.controller,
    this.bottomOffset = aboveTabBar,
  });

  final Widget child;

  /// Defaults to [appMessageController].
  final AppMessageController? controller;

  /// Distance from the bottom safe area, [aboveTabBar] by default.
  final double bottomOffset;

  /// Clears the bottom tab bar of the app.
  static const double aboveTabBar = 76;

  static const Duration durationWithAction = Duration(seconds: 6);
  static const Duration durationWithoutAction = Duration(milliseconds: 2500);

  @override
  State<AppMessageHost> createState() => _AppMessageHostState();
}

class _AppMessageHostState extends State<AppMessageHost> {
  Timer? _timer;
  AppMessage? _scheduledFor;

  AppMessageController get _controller =>
      widget.controller ?? appMessageController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(AppMessageHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.controller ?? appMessageController;
    if (old != _controller) {
      old.removeListener(_onChanged);
      old._clearIfUnattached();
      _controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onChanged);
    _controller._clearIfUnattached();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _schedule(AppMessage? message, {required bool keepUntilDismissed}) {
    if (identical(message, _scheduledFor)) return;
    _scheduledFor = message;
    _timer?.cancel();
    _timer = null;
    if (message == null || keepUntilDismissed) return;
    _timer = Timer(message.duration, () {
      if (identical(_controller.current, message)) _controller.dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _controller.current;
    final media = MediaQuery.of(context);
    // A screen reader user needs more than 6 s to reach the action: keep the
    // message until it is used or replaced.
    _schedule(
      message,
      keepUntilDismissed:
          message != null && message.hasAction && media.accessibleNavigation,
    );

    return Stack(
      children: [
        widget.child,
        if (message != null)
          Positioned(
            left: 12,
            right: 12,
            bottom:
                widget.bottomOffset +
                media.padding.bottom +
                media.viewInsets.bottom,
            child: _MessageBar(
              key: ValueKey(message),
              message: message,
              onAction: () {
                _controller.dismiss();
                message.onAction?.call();
              },
            ),
          ),
      ],
    );
  }
}

class _MessageBar extends StatelessWidget {
  const _MessageBar({super.key, required this.message, required this.onAction});

  final AppMessage message;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: colors.text,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Text(
                    message.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.bg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              if (message.hasAction)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.bg,
                    minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(message.actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
