import 'package:flutter/material.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Storage & History'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage & Data'),
            subtitle: const Text('Manage cache, exports, and viewing history database.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DataCacheSettingsPage()),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'MediaVore',
            applicationVersion: '1.0.0',
            aboutBoxChildren: [
              Text('A simple media tracking app using TMDB.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
