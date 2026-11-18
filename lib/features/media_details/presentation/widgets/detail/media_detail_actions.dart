import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Adds [item] to [listName] or removes it, and confirms with a message
/// offering "Undo".
Future<void> toggleListWithFeedback(
  BuildContext context,
  MediaItem item,
  String listName,
) async {
  final provider = context.read<SearchProvider>();
  final l10n = context.l10n;
  final wasIn = provider.isItemInList(item, listName);
  await provider.toggleInList(item, listName);
  final name = listDisplayName(l10n, listName);
  showAppMessage(
    wasIn ? l10n.detailRemovedFromList(name) : l10n.detailAddedToList(name),
    actionLabel: l10n.commonUndo,
    onAction: () {
      if (provider.isItemInList(item, listName) != wasIn) {
        provider.toggleInList(item, listName);
      }
    },
  );
}

/// The two buttons under the header: the list split button and the main
/// action ([primary], e.g. "Mark as seen"). They stack when the text is too
/// large to sit side by side.
class MediaDetailActions extends StatelessWidget {
  const MediaDetailActions({super.key, required this.item, this.primary});

  final MediaItem item;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    final split = ListSplitButton(item: item);
    final primary = this.primary;
    if (primary == null) return split;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth / scale < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [split, const SizedBox(height: 8), primary],
          );
        }
        return Row(
          children: [
            Expanded(child: split),
            const SizedBox(width: 8),
            Expanded(child: primary),
          ],
        );
      },
    );
  }
}

/// Double button: the main part adds the title to the first list in one tap
/// (or removes it); the arrow opens every list, with a badge counting the
/// other lists that already hold the title.
class ListSplitButton extends StatelessWidget {
  const ListSplitButton({super.key, required this.item});

  final MediaItem item;

  @visibleForTesting
  static const Key mainKey = Key('media_detail_list_main');
  @visibleForTesting
  static const Key menuKey = Key('media_detail_list_menu');
  @visibleForTesting
  static const Key badgeKey = Key('media_detail_list_badge');

  Future<void> _openMenu(BuildContext context, SearchProvider provider) async {
    final l10n = context.l10n;
    final chosen = await showAppMenu<String>(
      context: context,
      title: l10n.detailChooseList,
      items: [
        for (final name in provider.listNames)
          AppMenuItem(
            value: name,
            label: listDisplayName(l10n, name),
            icon: provider.isItemInList(item, name) ? Icons.check : Icons.add,
          ),
      ],
    );
    if (chosen == null || !context.mounted) return;
    await toggleListWithFeedback(context, item, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final provider = context.watch<SearchProvider>();
    final first = provider.firstListName;
    final firstLabel = listDisplayName(l10n, first);
    final inFirst = provider.isItemInList(item, first);
    final others = provider.listNames
        .where((name) => name != first && provider.isItemInList(item, name))
        .length;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: inFirst
                      ? l10n.detailInListRemove(firstLabel)
                      : l10n.detailAddToList(firstLabel),
                  excludeSemantics: true,
                  child: InkWell(
                    key: mainKey,
                    onTap: () => toggleListWithFeedback(context, item, first),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            inFirst ? Icons.check : Icons.add,
                            size: 18,
                            color: colors.text,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              firstLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: colors.border),
              Semantics(
                button: true,
                label: l10n.detailChooseListOthers(others),
                excludeSemantics: true,
                child: InkWell(
                  key: menuKey,
                  onTap: () => _openMenu(context, provider),
                  child: SizedBox(
                    width: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: colors.text,
                        ),
                        if (others > 0)
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: Container(
                              key: badgeKey,
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.text,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$others',
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: colors.bg,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
