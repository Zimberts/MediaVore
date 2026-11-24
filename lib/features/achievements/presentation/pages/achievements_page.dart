import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const List<String> achievementOrderedCategories = [
  'movies',
  'tv',
  'books',
  'discovery',
  'together',
  'regularity',
];

String categoryTitle(BuildContext context, String categoryId) {
  switch (categoryId) {
    case 'movies':
      return context.l10n.achievementsCategoryMovies;
    case 'tv':
      return context.l10n.achievementsCategoryTv;
    case 'books':
      return context.l10n.achievementsCategoryBooks;
    case 'discovery':
      return context.l10n.achievementsCategoryDiscovery;
    case 'together':
      return context.l10n.achievementsCategoryTogether;
    case 'regularity':
      return context.l10n.achievementsCategoryRegularity;
    default:
      return categoryId;
  }
}

Color categoryColor(BuildContext context, String categoryId) {
  final colors = context.appColors;
  switch (categoryId) {
    case 'movies':
      return colors.movie;
    case 'tv':
      return colors.series;
    case 'books':
      return colors.book;
    case 'discovery':
      return colors.warning;
    case 'together':
      return colors.duo;
    case 'regularity':
      return colors.success;
    default:
      return colors.primary;
  }
}

sealed class _AchievementsListItem {}

class _CategoryHeaderItem extends _AchievementsListItem {
  final String categoryId;
  _CategoryHeaderItem(this.categoryId);
}

class _FamilyCardItem extends _AchievementsListItem {
  final AchievementFamily family;
  _FamilyCardItem(this.family);
}

class AchievementsPage extends StatefulWidget {
  static const routeName = '/achievements';

  final String? initialAchievementId;
  const AchievementsPage({super.key, this.initialAchievementId});

  /// Named route, so the page can be found in the navigator stack.
  static Route<void> route({String? initialAchievementId}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) =>
          AchievementsPage(initialAchievementId: initialAchievementId),
    );
  }

  /// States of the pages currently mounted, oldest first.
  static final List<_AchievementsPageState> _mounted = [];

  /// Shows [achievementId] without stacking a second page: if an
  /// [AchievementsPage] is already in [navigator]'s stack, pops back to it and
  /// scrolls to (and highlights) the achievement's family; otherwise pushes a
  /// new page.
  static void showAchievement(NavigatorState navigator, String achievementId) {
    if (_mounted.isEmpty) {
      navigator.push(route(initialAchievementId: achievementId));
      return;
    }
    navigator.popUntil(
      (route) => route.settings.name == routeName || route.isFirst,
    );
    _mounted.last.focusAchievement(achievementId);
  }

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  String? _focusedId;

  @override
  void initState() {
    super.initState();
    AchievementsPage._mounted.add(this);
    _focusedId = widget.initialAchievementId;
    if (_focusedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusedId != null) _scrollToAchievement(_focusedId!);
      });
    }
  }

  @override
  void dispose() {
    AchievementsPage._mounted.remove(this);
    super.dispose();
  }

  /// Highlights [id]'s family and scrolls to it.
  void focusAchievement(String id) {
    setState(() => _focusedId = id);
    _scrollToAchievement(id);
  }

  List<_AchievementsListItem> _buildListItems(
    List<AchievementFamily> families,
  ) {
    final listItems = <_AchievementsListItem>[];
    for (final cat in achievementOrderedCategories) {
      final inCat = families.where((f) => f.category == cat).toList();
      if (inCat.isEmpty) continue;
      listItems.add(_CategoryHeaderItem(cat));
      for (final fam in inCat) {
        listItems.add(_FamilyCardItem(fam));
      }
    }

    // Include any unrecognized categories at the end if present
    final remaining = families
        .where((f) => !achievementOrderedCategories.contains(f.category))
        .toList();
    if (remaining.isNotEmpty) {
      final extraCats = remaining.map((f) => f.category).toSet();
      for (final cat in extraCats) {
        listItems.add(_CategoryHeaderItem(cat));
        for (final fam in remaining.where((f) => f.category == cat)) {
          listItems.add(_FamilyCardItem(fam));
        }
      }
    }

    return listItems;
  }

  void _scrollToAchievement(String id) {
    if (!_itemScrollController.isAttached) return;
    final provider = context.read<AchievementProvider>();
    final listItems = _buildListItems(provider.families);

    final index = listItems.indexWhere(
      (item) => item is _FamilyCardItem && item.family.contains(id),
    );
    if (index != -1) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();
    final families = provider.families;

    final unlockedCount = provider.achievements
        .where((a) => a.isUnlocked)
        .length;
    final totalCount = provider.achievements.length;
    final completedFamilies = families.where((f) => f.isCompleted).length;

    final listItems = _buildListItems(families);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileAchievements)),
      body: families.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _AchievementsSummary(
                  unlockedCount: unlockedCount,
                  totalCount: totalCount,
                  completedFamilies: completedFamilies,
                  totalFamilies: families.length,
                ),
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      final item = listItems[index];
                      if (item is _CategoryHeaderItem) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: index == 0 ? 12 : 24,
                            bottom: 12,
                          ),
                          child: Text(
                            categoryTitle(context, item.categoryId),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      } else if (item is _FamilyCardItem) {
                        final family = item.family;
                        final focusedId = _focusedId;
                        return _FamilyCard(
                          family: family,
                          isHighlighted:
                              focusedId != null && family.contains(focusedId),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _AchievementsSummary extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;
  final int completedFamilies;
  final int totalFamilies;

  const _AchievementsSummary({
    required this.unlockedCount,
    required this.totalCount,
    required this.completedFamilies,
    required this.totalFamilies,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percentage = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.achievementsOverall,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.l10n.achievementsUnlockedCount(
                        unlockedCount,
                        totalCount,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.text2),
                    ),
                    Text(
                      context.l10n.achievementsChallengesCompleted(
                        completedFamilies,
                        totalFamilies,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.text2),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final AchievementFamily family;
  final bool isHighlighted;

  const _FamilyCard({required this.family, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final current = family.current;
    final next = family.next;
    final isUnlocked = current.isUnlocked;
    final languageCode = context.l10n.localeName;
    final catColor = categoryColor(context, family.category);

    final title = (family.isTiered && isUnlocked)
        ? context.l10n.achievementsLevelTitle(
            family.highestUnlocked?.tier ?? 1,
            family.titleFor(languageCode),
          )
        : family.titleFor(languageCode);

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border.all(color: catColor, width: 2) : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _showTiers(context, family),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AchievementBadge(
                  isUnlocked: isUnlocked,
                  isCompleted: family.isCompleted,
                  categoryColor: catColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (family.isTiered) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${family.unlockedCount}/${family.tiers.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.descriptionFor(languageCode),
                        style: TextStyle(color: colors.text2),
                      ),
                      if (family.isTiered) ...[
                        const SizedBox(height: 8),
                        _TierDots(family: family, color: catColor),
                      ],
                      if (next != null && next.progress > 0) ...[
                        const SizedBox(height: 8),
                        _ProgressBar(achievement: next, color: catColor),
                        const SizedBox(height: 4),
                        Text(
                          family.isTiered && isUnlocked
                              ? context.l10n.achievementsNextLevel(
                                  next.titleFor(languageCode),
                                  next.progressLabel ?? '',
                                )
                              : next.progressLabel ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (family.isCompleted && current.unlockedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          family.isTiered
                              ? context.l10n.achievementsAllLevelsCompleted
                              : context.l10n.achievementsUnlockedOn(
                                  _formatDate(current.unlockedAt!),
                                ),
                          style: TextStyle(
                            color: colors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (isUnlocked && current.unlockedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.achievementsUnlockedOn(
                            _formatDate(current.unlockedAt!),
                          ),
                          style: TextStyle(
                            color: colors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTiers(BuildContext context, AchievementFamily family) {
    final catColor = categoryColor(context, family.category);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                family.titleFor(context.l10n.localeName),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final tier in family.tiers)
              _TierTile(
                achievement: tier,
                isNextGoal: tier == family.next,
                categoryColor: catColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final Achievement achievement;
  final bool isNextGoal;
  final Color categoryColor;

  const _TierTile({
    required this.achievement,
    required this.isNextGoal,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUnlocked = achievement.isUnlocked;
    final languageCode = context.l10n.localeName;
    final title = achievement.titleFor(languageCode);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _AchievementBadge(
        isUnlocked: isUnlocked,
        categoryColor: categoryColor,
        size: 44,
      ),
      title: Text(
        achievement.tier != null
            ? context.l10n.achievementsLevelTitle(achievement.tier!, title)
            : title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.descriptionFor(languageCode)),
          const SizedBox(height: 4),
          if (isUnlocked && achievement.unlockedAt != null)
            Text(
              context.l10n.achievementsUnlockedOn(
                _formatDate(achievement.unlockedAt!),
              ),
              style: TextStyle(
                color: colors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (isNextGoal) ...[
            _ProgressBar(achievement: achievement, color: categoryColor),
            const SizedBox(height: 4),
            if (achievement.progressLabel != null &&
                achievement.progressLabel!.isNotEmpty)
              Text(
                achievement.progressLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final bool isUnlocked;
  final bool isCompleted;
  final double size;
  final Color? categoryColor;

  const _AchievementBadge({
    required this.isUnlocked,
    this.isCompleted = false,
    this.size = 64,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = categoryColor ?? colors.primary;
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCompleted
              ? Icons.emoji_events
              : isUnlocked
              ? Icons.stars
              : Icons.stars_outlined,
          size: size / 2,
          color: isUnlocked ? tint : colors.text2,
        ),
      ),
    );
  }
}

class _TierDots extends StatelessWidget {
  final AchievementFamily family;
  final Color? color;

  const _TierDots({required this.family, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = color ?? colors.primary;
    return Row(
      children: [
        for (final tier in family.tiers)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              tier.isUnlocked ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: tier.isUnlocked ? activeColor : colors.text2,
            ),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.achievementsLevelProgress(
              family.unlockedCount,
              family.tiers.length,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.text2),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Achievement achievement;
  final Color? color;

  const _ProgressBar({required this.achievement, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = color ?? colors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: achievement.progress,
        minHeight: 6,
        backgroundColor: activeColor.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );
  }
}

String _formatDate(DateTime date) => DateFormat.yMMMd().format(date.toLocal());
