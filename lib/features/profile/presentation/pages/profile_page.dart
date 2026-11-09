import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_stats_page.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';

/// "Profile" tab: the single entry point to Stats, Achievements and Settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('profile_stats'),
            leading: const Icon(Icons.bar_chart),
            title: Text(l10n.profileStats),
            subtitle: Text(l10n.profileStatsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MediaStatsPage())),
          ),
          ListTile(
            key: const Key('profile_achievements'),
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(l10n.profileAchievements),
            subtitle: Text(l10n.profileAchievementsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(AchievementsPage.route()),
          ),
          const Divider(),
          ListTile(
            key: const Key('profile_settings'),
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.profileSettings),
            subtitle: Text(l10n.profileSettingsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
    );
  }
}
