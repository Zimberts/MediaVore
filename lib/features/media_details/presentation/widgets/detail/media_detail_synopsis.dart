import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/section_header.dart';

/// Synopsis folded to [collapsedLines] lines with "Read more". Draws nothing
/// when [text] is empty.
class MediaDetailSynopsis extends StatefulWidget {
  const MediaDetailSynopsis({super.key, required this.text});

  final String text;

  static const int collapsedLines = 4;

  @visibleForTesting
  static const Key textKey = Key('media_detail_synopsis');

  @override
  State<MediaDetailSynopsis> createState() => _MediaDetailSynopsisState();
}

class _MediaDetailSynopsisState extends State<MediaDetailSynopsis> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.detailOverview),
        LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: MediaDetailSynopsis.collapsedLines,
            )..layout(maxWidth: constraints.maxWidth);
            final overflows = painter.didExceedMaxLines;
            painter.dispose();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  key: MediaDetailSynopsis.textKey,
                  style: style,
                  maxLines: _open ? null : MediaDetailSynopsis.collapsedLines,
                  overflow: _open ? null : TextOverflow.ellipsis,
                ),
                if (overflows)
                  Material(
                    type: MaterialType.transparency,
                    child: AppTapTarget(
                      onTap: () => setState(() => _open = !_open),
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        _open ? l10n.detailReadLess : l10n.detailReadMore,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.appColors.text,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
