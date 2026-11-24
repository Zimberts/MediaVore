import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/domain/entities/achievement.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/pages/tmdb_credential_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Pure helper to count the number of distinct calendar days with seen items
/// within the last 30 days from [referenceTime].
int countActiveDaysInLast30Days(
  List<SeenItem> items, {
  DateTime? referenceTime,
}) {
  final now = referenceTime ?? DateTime.now();
  final cutoff = now.subtract(const Duration(days: 30));
  final activeDays = <String>{};
  for (final item in items) {
    if (item.seenDate.isAfter(cutoff) && !item.seenDate.isAfter(now)) {
      final key =
          '${item.seenDate.year}-${item.seenDate.month.toString().padLeft(2, '0')}-${item.seenDate.day.toString().padLeft(2, '0')}';
      activeDays.add(key);
    }
  }
  return activeDays.length;
}

/// Pure helper to select 4 preview achievements:
/// Up to 3 unlocked achievements, and the locked achievement closest to unlocking
/// (highest progress), filling up to 4 achievements total.
List<Achievement> selectPreviewAchievements(List<Achievement> all) {
  if (all.isEmpty) return const [];
  final unlocked = all.where((a) => a.isUnlocked).toList();
  final locked = all.where((a) => !a.isUnlocked).toList();
  // Sort locked by progress descending (closest to unlock first)
  locked.sort((a, b) => b.progress.compareTo(a.progress));

  final preview = <Achievement>[];
  preview.addAll(unlocked.take(3));
  final remaining = 4 - preview.length;
  if (remaining > 0) {
    preview.addAll(locked.take(remaining));
  }
  if (preview.length < 4 && unlocked.length > preview.length) {
    preview.addAll(unlocked.skip(preview.length).take(4 - preview.length));
  }
  return preview;
}

/// Formats the TMDB API key to reveal only the last 4 characters.
String formatMaskedTmdbKey(String key) {
  if (key.isEmpty) return '';
  final last4 = key.length > 4 ? key.substring(key.length - 4) : key;
  return '••••$last4';
}

/// "Moi" (Profile) tab: key figures, achievement preview, and settings shortcuts.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);

    final searchProvider = context.watch<SearchProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final achievementProvider = context.watch<AchievementProvider>();

    final seenItems = searchProvider.seenItems;
    final activeDays = countActiveDaysInLast30Days(seenItems);

    // Compute key figures identical to MediaStatsPage on "Tout"
    final movieCount = seenItems.where((i) => i.type == MediaType.movie).length;
    final tvCount = seenItems.where((i) => i.type == MediaType.tv).length;
    final totalMinutes = seenItems.fold<int>(
      0,
      (sum, item) => sum + (item.runtime ?? 0),
    );
    final totalHours = totalMinutes ~/ 60;

    // Achievements preview
    final allAchievements = achievementProvider.achievements;
    final unlockedCount = allAchievements.where((a) => a.isUnlocked).length;
    final totalCount = allAchievements.length;
    final previewAchievements = selectPreviewAchievements(allAchievements);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header: Avatar + Title + Active days
          _ProfileHeader(activeDaysText: l10n.profileActiveDays(activeDays)),
          const SizedBox(height: 20),

          // En chiffres: Two colored tiles (Books hidden until #298)
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.movie_outlined,
                  color: colors.primary,
                  value: '$movieCount',
                  label: l10n.profileMoviesWatched,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.tv_outlined,
                  color: colors.series,
                  value: '$tvCount',
                  label: l10n.profileEpisodesAndScreen,
                  subtitle: l10n.profileScreenTime(totalHours),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "Toutes les statistiques" button
          OutlinedButton.icon(
            key: const Key('profile_stats'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MediaStatsPage()),
            ),
            icon: const Icon(Icons.bar_chart),
            label: Text(l10n.profileAllStats),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Achievements section header
          // Wraps the link under the title when both don't fit (narrow
          // screen, large text) instead of truncating either.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.profileAchievements,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                key: const Key('profile_achievements'),
                onPressed: () =>
                    Navigator.of(context).push(AchievementsPage.route()),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  l10n.profileAchievementsSeeAll(unlockedCount, totalCount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Achievements preview: 4 items (3 unlocked + 1 closest)
          if (previewAchievements.isNotEmpty)
            _AchievementsGrid(
              achievements: previewAchievements,
              languageCode: l10n.localeName,
            ),

          const SizedBox(height: 20),
          const Divider(),

          // Settings entries
          ListTile(
            key: const Key('profile_settings'),
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.profileSettings),
            subtitle: Text(l10n.profileSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
          ListTile(
            key: const Key('profile_tmdb_credential'),
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.settingsTmdbCredential),
            subtitle: Text(
              settingsProvider.tmdbApiKey.isEmpty
                  ? l10n.settingsNotSet
                  : formatMaskedTmdbKey(settingsProvider.tmdbApiKey),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TmdbCredentialPage(),
              ),
            ),
          ),
          ListTile(
            key: const Key('profile_storage'),
            leading: const Icon(Icons.storage_outlined),
            title: Text(l10n.settingsStorage),
            subtitle: Text(l10n.settingsStorageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DataCacheSettingsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String activeDaysText;

  const _ProfileHeader({required this.activeDaysText});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: colors.primary.withValues(alpha: 0.15),
          child: Text(
            'M',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.profileTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeDaysText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.text2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? subtitle;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.text2),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final String languageCode;

  const _AchievementsGrid({
    required this.achievements,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < achievements.length; i += 2) {
      final first = achievements[i];
      final second = i + 1 < achievements.length ? achievements[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: _PreviewAchievementCard(
                achievement: first,
                languageCode: languageCode,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: second != null
                  ? _PreviewAchievementCard(
                      achievement: second,
                      languageCode: languageCode,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < achievements.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
  }
}

class _PreviewAchievementCard extends StatelessWidget {
  final Achievement achievement;
  final String languageCode;

  const _PreviewAchievementCard({
    required this.achievement,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnlocked
              ? colors.primary.withValues(alpha: 0.3)
              : colors.text2.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AchievementsPage.showAchievement(
            Navigator.of(context),
            achievement.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.text2.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked ? Icons.stars : Icons.stars_outlined,
                    color: isUnlocked ? colors.primary : colors.text2,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.titleFor(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isUnlocked)
                      Text(
                        context.l10n.profileUnlocked,
                        style: TextStyle(
                          color: colors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: achievement.progress,
                          minHeight: 4,
                          backgroundColor: colors.primary.withValues(
                            alpha: 0.1,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement.progressLabel ??
                            '${(achievement.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: colors.text2,
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
