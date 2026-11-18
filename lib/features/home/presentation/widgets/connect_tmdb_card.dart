import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_card.dart';

/// Shown instead of the blocks that need the network while no TMDB
/// credential is set.
class ConnectTmdbCard extends StatelessWidget {
  const ConnectTmdbCard({super.key, required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 24, color: context.appColors.text),
          const SizedBox(height: 8),
          Text(
            l10n.homeConnectTmdbTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeConnectTmdbMessage,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.link, size: 18),
            label: Text(l10n.homeConnectTmdbAction),
          ),
        ],
      ),
    );
  }
}
