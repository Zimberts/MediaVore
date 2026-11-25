import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// Banner telling that the app is offline, with what it means on the screen
/// that shows it. With another [icon] and [title], it reports another
/// failure to reach TMDB the same way.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.wifi_off,
  });

  /// Leading icon; the "no network" one by default.
  final IconData icon;

  /// Bold lead; "Offline" by default.
  final String? title;

  /// What is unavailable, or what will happen when the network is back.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4);
    final title = this.title ?? context.l10n.offlineBannerTitle;
    final message = this.message;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.text),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (message != null) TextSpan(text: ' · $message'),
                  ],
                ),
                style: style?.copyWith(color: colors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
