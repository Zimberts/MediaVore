import 'package:flutter/material.dart';

/// A top-anchored scrim that fades the app background colour into transparency.
///
/// Placed over the expanded [SliverAppBar] artwork (posters, actor portraits),
/// it keeps the pinned title and action icons readable when the image behind
/// them is light or busy. The scrim is strongest at the very top (fully opaque
/// background colour) and fades to fully transparent over [height].
class TopScrimGradient extends StatelessWidget {
  /// How far down the scrim fades. Defaults to the status-bar inset + 120px.
  final double? height;

  /// Scrim colour. Defaults to the current theme's `scaffoldBackgroundColor`.
  final Color? color;

  /// Opacity of the scrim at the very top edge.
  final double startOpacity;

  /// Opacity at [midStop], before fading out to fully transparent.
  final double midOpacity;

  /// Position (0..1) of the [midOpacity] colour stop.
  final double midStop;

  const TopScrimGradient({
    super.key,
    this.height,
    this.color,
    this.startOpacity = 1.0,
    this.midOpacity = 0.85,
    this.midStop = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).scaffoldBackgroundColor;
    final scrimHeight =
        height ?? (MediaQuery.of(context).padding.top + 120.0);

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: scrimHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: startOpacity),
                base.withValues(alpha: midOpacity),
                base.withValues(alpha: 0.0),
              ],
              stops: [0.0, midStop, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
