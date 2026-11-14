import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// Opens the bottom sheet of the design: rounded top, grab handle, content
/// that scrolls when it is taller than 88 % of the screen.
///
/// [builder] returns the content only; the sheet adds the handle, the
/// padding, the safe area and the room for the keyboard.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  final colors = context.appColors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => _AppSheetBody(child: builder(context)),
  );
}

class _AppSheetBody extends StatelessWidget {
  const _AppSheetBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
