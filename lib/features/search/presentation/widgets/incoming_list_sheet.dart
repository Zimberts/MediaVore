import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/prompt_field.dart';
import 'package:mediavore/features/search/presentation/pages/list_intersection_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Shows the choice bottom sheet when an incoming shared list link or QR code is detected:
/// either compare with one of the user's lists, or import it.
void showIncomingListOptionsSheet({
  required BuildContext context,
  required ListSharePayload payload,
  VoidCallback? onImportComplete,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (modalContext) {
      final colors = Theme.of(modalContext).colorScheme;
      final textTheme = Theme.of(modalContext).textTheme;
      final displayName = payload.name.isNotEmpty
          ? payload.name
          : modalContext.l10n.listsIncomingSharedTitle;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.share, color: colors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                modalContext.l10n.listsIncomingSharedMessage(
                  displayName,
                  payload.entries.length,
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('incoming_list_compare_button'),
                icon: const Icon(Icons.compare_arrows),
                label: Text(modalContext.l10n.listsCompareWithMine),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(modalContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          ListIntersectionPage(sharedPayload: payload),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('incoming_list_import_button'),
                icon: const Icon(Icons.download),
                label: Text(modalContext.l10n.listsImportOptionTitle),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(modalContext);
                  _showImportDialog(context, payload, onImportComplete);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showImportDialog(
  BuildContext context,
  ListSharePayload payload,
  VoidCallback? onImportComplete,
) {
  var listName = payload.name;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.importListTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dialogContext.l10n.importListMessage(payload.entries.length)),
          const SizedBox(height: 16),
          PromptField(
            initialText: payload.name,
            autofocus: false,
            label: dialogContext.l10n.importListNameLabel,
            hint: dialogContext.l10n.importListNameHint,
            onChanged: (value) => listName = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.l10n.commonCancel),
        ),
        TextButton(
          onPressed: () async {
            final provider = context.read<SearchProvider>();
            final entries = payload.entries
                .map((e) => '${e.id}:${e.type.name}')
                .toList();
            await provider.importList(listName, entries);
            if (dialogContext.mounted) {
              Navigator.pop(dialogContext);
            }
            onImportComplete?.call();
          },
          child: Text(dialogContext.l10n.commonImport),
        ),
      ],
    ),
  );
}
