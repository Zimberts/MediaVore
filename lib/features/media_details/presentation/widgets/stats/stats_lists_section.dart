import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';

class ListsAndDiscoverySection extends StatelessWidget {
  final int watchlistCount;
  final int customListsCount;
  final int customListsItemsCount;

  const ListsAndDiscoverySection({
    super.key,
    required this.watchlistCount,
    required this.customListsCount,
    required this.customListsItemsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ItemRow(
          icon: Icons.bookmark_outline,
          label: context.l10n.statsWatchlistCount(watchlistCount),
        ),
        const SizedBox(height: 10),
        _ItemRow(
          icon: Icons.format_list_bulleted,
          label: context.l10n.statsCustomListsCount(
            customListsCount,
            customListsItemsCount,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ItemRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
