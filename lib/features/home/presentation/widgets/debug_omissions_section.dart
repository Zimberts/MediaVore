import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_card.dart';
import 'package:mediavore/core/widgets/section_header.dart';

/// A hidden item of a debug section: what it is and why it is not shown.
class DebugOmissionEntry {
  const DebugOmissionEntry({required this.title, required this.detail});

  final String title;
  final String detail;
}

/// Hidden items sharing the same reason.
class DebugOmissionGroup {
  const DebugOmissionGroup({required this.reason, required this.entries});

  /// Localized reason, used as the label of the group.
  final String reason;
  final List<DebugOmissionEntry> entries;
}

/// Debug-only block at the bottom of a list: the items that exist in the
/// database but are hidden above, grouped by reason.
///
/// Only build it when the notification debug setting is on.
class DebugOmissionsSection extends StatelessWidget {
  const DebugOmissionsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.groups,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;

  /// Groups in display order; empty groups are skipped.
  final List<DebugOmissionGroup> groups;

  /// The diagnostic is being computed.
  final bool loading;

  /// Link of the header ("Recompute"); hidden while [loading].
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final shown = [
      for (final group in groups)
        if (group.entries.isNotEmpty) group,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.bug_report_outlined, size: 18, color: colors.text2),
            const SizedBox(width: 8),
            Expanded(
              child: SectionHeader(
                title: title,
                actionLabel: actionLabel,
                onAction: loading ? null : onAction,
              ),
            ),
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        Text(subtitle, style: textTheme.bodySmall),
        if (!loading && shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.debugNothingOmitted, style: textTheme.bodySmall),
          ),
        for (final group in shown) ...[
          const SizedBox(height: 12),
          Text(
            l10n.debugGroupCount(group.reason, group.entries.length),
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < group.entries.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.entries[i].title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          group.entries[i].detail,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
