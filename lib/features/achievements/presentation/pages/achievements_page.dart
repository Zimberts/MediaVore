import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement_family.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AchievementsPage extends StatefulWidget {
  final String? initialAchievementId;
  const AchievementsPage({super.key, this.initialAchievementId});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAchievementId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAchievement(widget.initialAchievementId!);
      });
    }
  }

  void _scrollToAchievement(String id) {
    final provider = context.read<AchievementProvider>();
    final index = provider.families.indexWhere((f) => f.contains(id));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: families.length,
                    itemBuilder: (context, index) {
                      final family = families[index];
                      final initialId = widget.initialAchievementId;
                      return _FamilyCard(
                        family: family,
                        isHighlighted:
                            initialId != null && family.contains(initialId),
                      );
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
          bottom: BorderSide(
            color: colors.logicFlow.withValues(alpha: 0.1),
            width: 1,
          ),
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
                      'Overall Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'You\'ve unlocked $unlockedCount out of $totalCount badges',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.comments),
                    ),
                    Text(
                      '$completedFamilies / $totalFamilies challenges completed',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.comments),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.logicFlow,
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
              backgroundColor: colors.logicFlow.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colors.logicFlow),
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

    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: colors.logicFlow, width: 2)
            : null,
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
              children: [
                _AchievementBadge(
                  isUnlocked: isUnlocked,
                  isCompleted: family.isCompleted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        current.description,
                        style: TextStyle(color: colors.comments),
                      ),
                      if (family.isTiered) ...[
                        const SizedBox(height: 6),
                        _TierDots(family: family),
                      ],
                      if (next != null && next.progress > 0) ...[
                        const SizedBox(height: 8),
                        _ProgressBar(achievement: next),
                        const SizedBox(height: 4),
                        Text(
                          family.isTiered && isUnlocked
                              ? 'Next: ${next.title} · ${next.progressLabel ?? ''}'
                              : next.progressLabel ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (family.isCompleted && current.unlockedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          family.isTiered
                              ? 'All levels completed'
                              : 'Unlocked on ${_formatDate(current.unlockedAt!)}',
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
            for (final tier in family.tiers) _TierTile(achievement: tier),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  final Achievement achievement;

  const _TierTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUnlocked = achievement.isUnlocked;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _AchievementBadge(isUnlocked: isUnlocked, size: 44),
      title: Text(
        achievement.tier != null
            ? 'Level ${achievement.tier} · ${achievement.title}'
            : achievement.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.description),
          const SizedBox(height: 4),
          if (isUnlocked && achievement.unlockedAt != null)
            Text(
              'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
              style: TextStyle(
                color: colors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            _ProgressBar(achievement: achievement),
            const SizedBox(height: 2),
            Text(
              achievement.progressLabel ?? '',
              style: Theme.of(context).textTheme.bodySmall,
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

  const _AchievementBadge({
    required this.isUnlocked,
    this.isCompleted = false,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.3,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.logicFlow.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCompleted
              ? Icons.emoji_events
              : isUnlocked
              ? Icons.stars
              : Icons.stars_outlined,
          size: size / 2,
          color: isUnlocked ? colors.logicFlow : colors.comments,
        ),
      ),
    );
  }
}

class _TierDots extends StatelessWidget {
  final AchievementFamily family;

  const _TierDots({required this.family});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        for (final tier in family.tiers)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              tier.isUnlocked ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: tier.isUnlocked ? colors.logicFlow : colors.comments,
            ),
          ),
        const SizedBox(width: 4),
        Text(
          'Level ${family.unlockedCount}/${family.tiers.length}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.comments),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Achievement achievement;

  const _ProgressBar({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LinearProgressIndicator(
      value: achievement.progress,
      backgroundColor: colors.logicFlow.withValues(alpha: 0.1),
      valueColor: AlwaysStoppedAnimation<Color>(colors.logicFlow),
    );
  }
}

String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];
