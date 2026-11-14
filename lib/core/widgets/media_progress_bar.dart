import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/media_kind.dart';

/// Progress bar tinted with the color of a media type.
class MediaProgressBar extends StatelessWidget {
  const MediaProgressBar({
    super.key,
    required this.value,
    required this.kind,
    this.height = 6,
    this.semanticLabel,
  });

  /// Progress from 0 to 1; values outside that range are clamped.
  final double value;
  final MediaKind kind;
  final double height;

  /// What is progressing, for screen readers (e.g. "12 / 24 episodes").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final progress = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2);

    return Semantics(
      label: semanticLabel,
      value: '${(progress * 100).round()} %',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: colors.surface2,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kind.color(colors),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
