import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/achievements/presentation/pages/achievements_page.dart';
import 'package:mediavore/features/settings/presentation/pages/data_cache_settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dropdownStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.settingsSectionAppearance),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButtonHideUnderline(
              key: const Key('settings_language_dropdown'),
              // `null` value = follow the device ("System").
              child: DropdownButton<AppLanguage?>(
                value: settings.appLanguageOverride,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.setAppLanguage,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: [
                  DropdownMenuItem<AppLanguage?>(
                    value: null,
                    child: Text(l10n.settingsLanguageSystem),
                  ),
                  for (final language in supportedAppLanguages)
                    DropdownMenuItem<AppLanguage?>(
                      value: language,
                      child: Text(language.nativeName),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsThemeMode),
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
                    child: Text(_getThemeModeName(l10n, mode)),
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
                        Text(_getThemeModeName(l10n, mode)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsLightTheme),
            enabled: settings.themeMode != ThemeMode.dark,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: settings.lightAppThemeIndex,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.dark
                    ? (themeIndex) => themeIndex != null
                          ? settings.setLightAppTheme(themeIndex)
                          : null
                    : null,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                disabledHint: Text(
                  lightThemes[settings.lightAppThemeIndex].name,
                ),
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
            title: Text(l10n.settingsDarkTheme),
            enabled: settings.themeMode != ThemeMode.light,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: settings.darkAppThemeIndex,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.light
                    ? (themeIndex) => themeIndex != null
                          ? settings.setDarkAppTheme(themeIndex)
                          : null
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
          _SectionHeader(title: l10n.settingsSectionMilestones),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(l10n.settingsAchievements),
            subtitle: Text(l10n.settingsAchievementsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsPage(),
                ),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionListsDisplay),
          SwitchListTile(
            title: Text(l10n.settingsHideNonReleased),
            subtitle: Text(l10n.settingsHideNonReleasedSubtitle),
            value: settings.hideNonReleased,
            onChanged: (val) => settings.setHideNonReleased(val),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionStorage),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(l10n.settingsStorage),
            subtitle: Text(l10n.settingsStorageSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataCacheSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionApi),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(l10n.settingsTmdbCredential),
            subtitle: Text(
              settings.tmdbApiKey.isEmpty
                  ? l10n.settingsNotSet
                  : '••••••••${settings.tmdbApiKey.length > 4 ? settings.tmdbApiKey.substring(settings.tmdbApiKey.length - 4) : ''}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showApiKeyDialog(context, settings);
            },
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionAbout),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: l10n.appTitle,
            applicationVersion: '1.1.0',
            aboutBoxChildren: [Text(l10n.settingsAboutDescription)],
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.settingsThemeModeSystem;
      case ThemeMode.light:
        return l10n.settingsThemeModeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeModeDark;
    }
  }

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.tmdbApiKey);
    showDialog(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.settingsTmdbCredential),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.tmdbCredentialHint,
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                settings.setTmdbApiKey(controller.text.trim());
                Navigator.pop(context);
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
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
