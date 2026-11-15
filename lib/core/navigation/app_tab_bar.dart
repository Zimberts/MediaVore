import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// Bottom tab bar of the design: the active tab is marked by a pill behind
/// its icon; "Together" uses the duo color.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<AppTab> tabs;
  final AppTab selected;
  final ValueChanged<AppTab> onSelected;

  /// Height of the bar above the bottom safe area.
  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabItem(
                      tab: tabs[i],
                      index: i,
                      count: tabs.length,
                      selected: tabs[i] == selected,
                      onTap: () => onSelected(tabs[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.index,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final int index;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final duo = tab == AppTab.together;
    final color = !selected
        ? colors.text2
        : duo
        ? colors.duo
        : colors.text;
    final pill = !selected
        ? null
        : duo
        ? colors.duoBg
        : colors.surface2;
    final label = tab.label(context.l10n);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      hint: MaterialLocalizations.of(
        context,
      ).tabLabel(tabIndex: index + 1, tabCount: count),
      child: InkWell(
        key: ValueKey(tab),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 30,
                decoration: BoxDecoration(
                  color: pill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  selected ? tab.selectedIcon : tab.icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              // Shrinks instead of truncating on narrow phones.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  // Already the label of the tab.
                  child: Text(
                    label,
                    semanticsLabel: '',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: color,
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
