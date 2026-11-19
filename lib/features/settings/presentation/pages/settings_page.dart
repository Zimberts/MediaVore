import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/app_version.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<String> supportedWatchProviderCountries = [
    'FR',
    'BE',
    'CH',
    'CA',
    'US',
    'GB',
    'DE',
    'ES',
    'IT',
    'AU',
    'BR',
    'JP',
    'KR',
    'NL',
    'PT',
  ];

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
            leading: const Icon(Icons.public),
            title: Text(l10n.settingsWatchProvidersCountry),
            subtitle: Text(l10n.settingsWatchProvidersCountrySubtitle),
            trailing: DropdownButtonHideUnderline(
              key: const Key('settings_watch_providers_country_dropdown'),
              child: DropdownButton<String?>(
                value: settings.watchProvidersCountry,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.setWatchProvidersCountry,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      l10n.settingsWatchProvidersCountrySystem(
                        l10n.detailCountryName(
                          settings.resolveWatchProvidersCountry(),
                        ),
                      ),
                    ),
                  ),
                  for (final code in [
                    ...supportedWatchProviderCountries,
                    if (settings.watchProvidersCountry != null &&
                        !supportedWatchProviderCountries.contains(
                          settings.watchProvidersCountry,
                        ))
                      settings.watchProvidersCountry!,
                  ])
                    DropdownMenuItem<String?>(
                      value: code,
                      child: Text(l10n.detailCountryName(code)),
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
              child: DropdownButton<AppPaletteId>(
                key: const Key('settings_light_palette_dropdown'),
                value: settings.lightPalette.id,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.dark
                    ? (id) => id != null ? settings.setLightPalette(id) : null
                    : null,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                disabledHint: Text(paletteName(l10n, settings.lightPalette.id)),
                items: AppPalette.lightPalettes.map((palette) {
                  return DropdownMenuItem(
                    value: palette.id,
                    child: Text(paletteName(l10n, palette.id)),
                  );
                }).toList(),
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsDarkTheme),
            enabled: settings.themeMode != ThemeMode.light,
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<AppPaletteId>(
                key: const Key('settings_dark_palette_dropdown'),
                value: settings.darkPalette.id,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: settings.themeMode != ThemeMode.light
                    ? (id) => id != null ? settings.setDarkPalette(id) : null
                    : null,
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                disabledHint: Text(paletteName(l10n, settings.darkPalette.id)),
                items: AppPalette.darkPalettes.map((palette) {
                  return DropdownMenuItem(
                    value: palette.id,
                    child: Text(paletteName(l10n, palette.id)),
                  );
                }).toList(),
              ),
            ),
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
          _SectionHeader(title: l10n.settingsSectionTracking),
          SwitchListTile(
            key: const Key('settings_advanced_tracking'),
            title: Text(l10n.settingsAdvancedTracking),
            subtitle: Text(l10n.settingsAdvancedTrackingSubtitle),
            value: settings.advancedTracking,
            onChanged: (val) => settings.setAdvancedTracking(val),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsSectionAbout),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: l10n.appTitle,
            applicationVersion: appVersion,
            aboutBoxChildren: [
              Text(l10n.settingsAboutDescription),
              const SizedBox(height: 8),
              Text(l10n.settingsAboutJustWatch),
            ],
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
