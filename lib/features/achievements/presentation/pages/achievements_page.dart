import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
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
    final index = provider.achievements.indexWhere((a) => a.id == id);
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

    final unlockedCount = provider.achievements.where((a) => a.isUnlocked).length;
    final totalCount = provider.achievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: provider.achievements.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _AchievementsSummary(
                  unlockedCount: unlockedCount,
                  totalCount: totalCount,
                ),
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = provider.achievements[index];
                      return _AchievementCard(
                        achievement: achievement,
                        isHighlighted: achievement.id == widget.initialAchievementId,
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

  const _AchievementsSummary({
    required this.unlockedCount,
    required this.totalCount,
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
              Column(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.comments,
                        ),
                  ),
                ],
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

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isHighlighted;

  const _AchievementCard({
    required this.achievement,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isUnlocked = achievement.isUnlocked;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.3,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.logicFlow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked ? Icons.stars : Icons.stars_outlined,
                    size: 32,
                    color: isUnlocked ? colors.logicFlow : colors.comments,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(color: colors.comments),
                    ),
                    if (!isUnlocked && achievement.progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: colors.logicFlow.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.logicFlow),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.progressLabel ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (isUnlocked && achievement.unlockedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unlocked on ${achievement.unlockedAt!.toLocal().toString().split(' ')[0]}',
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
    );
  }
}
