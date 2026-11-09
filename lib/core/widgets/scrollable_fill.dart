import 'package:flutter/material.dart';

/// Lays [child] out over the whole viewport inside an always-scrollable view.
///
/// A [RefreshIndicator] only reacts to scroll notifications, so a plain
/// `Center` (e.g. an empty state) cannot be pulled to refresh. Wrapping it in
/// [ScrollableFill] keeps it centered while making the pull gesture work.
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}
