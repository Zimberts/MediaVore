import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final dropdownStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                selectedItemBuilder: (context) => ThemeMode.values.map((mode) {
                  return Container(
                    alignment: Alignment.centerRight,
                    child: Text(_getThemeModeName(mode)),
                  );
                }).toList(),
                items: ThemeMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getThemeModeIcon(mode), size: 14),
                        const SizedBox(width: 6),
                        Text(_getThemeModeName(mode)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Light Theme'),
            enabled: settings.themeMode != ThemeMode.dark,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: settings.lightAppThemeIndex,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.dark
                    ? (themeIndex) => themeIndex != null ? settings.setLightAppTheme(themeIndex) : null
                    : null,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                disabledHint: Text(lightThemes[settings.lightAppThemeIndex].name),
                items: lightThemes.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.name),
                  );
                }).toList(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Dark Theme'),
            enabled: settings.themeMode != ThemeMode.light,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: settings.darkAppThemeIndex,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.light
                    ? (themeIndex) => themeIndex != null ? settings.setDarkAppTheme(themeIndex) : null
                    : null,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                disabledHint: Text(darkThemes[settings.darkAppThemeIndex].name),
                items: darkThemes.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.name),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'Lists Display'),
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

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return Icons.brightness_auto;
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
    }
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
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
