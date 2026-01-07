import 'package:flutter/material.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Display'),
          ListTile(
            title: const Text('Display Mode'),
            subtitle: Text(settings.displayMode.name.toUpperCase()),
            trailing: DropdownButton<DisplayMode>(
              value: settings.displayMode,
              onChanged: (mode) {
                if (mode != null) settings.setDisplayMode(mode);
              },
              items: DisplayMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.name.toUpperCase()),
                );
              }).toList(),
            ),
          ),
          if (settings.displayMode == DisplayMode.grid)
            ListTile(
              title: const Text('Grid Size (Items per row)'),
              subtitle: Slider(
                value: settings.gridSize,
                min: 2,
                max: 5,
                divisions: 3,
                label: settings.gridSize.round().toString(),
                onChanged: (val) => settings.setGridSize(val),
              ),
              trailing: Text(settings.gridSize.round().toString()),
            ),
          SwitchListTile(
            title: const Text('Hide Non-Released Media'),
            subtitle: const Text('Only show movies and episodes that have already aired.'),
            value: settings.hideNonReleased,
            onChanged: (val) => settings.setHideNonReleased(val),
          ),
          const Divider(),
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
