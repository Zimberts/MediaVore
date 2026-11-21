import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/app_version.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/app_segmented.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
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
          // 1. Apparence
          _SectionHeader(title: l10n.settingsSectionAppearance),

          // Language: Segmented if <= 3 options (System + <=2 languages), else dropdown
          if (supportedAppLanguages.length <= 2)
            _buildSegmentedOption<AppLanguage?>(
              context: context,
              label: l10n.settingsLanguage,
              key: const Key('settings_language_dropdown'),
              selected: settings.appLanguageOverride,
              onChanged: settings.setAppLanguage,
              segments: [
                AppSegment(value: null, label: l10n.settingsLanguageSystem),
                for (final language in supportedAppLanguages)
                  AppSegment(value: language, label: language.nativeName),
              ],
            )
          else
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              trailing: DropdownButtonHideUnderline(
                key: const Key('settings_language_dropdown'),
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

          // Theme Mode
          _buildSegmentedOption<ThemeMode>(
            context: context,
            label: l10n.settingsThemeMode,
            key: const Key('settings_theme_mode_segmented'),
            selected: settings.themeMode,
            onChanged: settings.setThemeMode,
            segments: [
              AppSegment(
                value: ThemeMode.system,
                label: _getThemeModeName(l10n, ThemeMode.system),
                icon: Icons.brightness_auto,
              ),
              AppSegment(
                value: ThemeMode.light,
                label: _getThemeModeName(l10n, ThemeMode.light),
                icon: Icons.light_mode,
              ),
              AppSegment(
                value: ThemeMode.dark,
                label: _getThemeModeName(l10n, ThemeMode.dark),
                icon: Icons.dark_mode,
              ),
            ],
          ),

          // Light Theme Palette
          _buildPaletteOption(
            context: context,
            label: l10n.settingsLightTheme,
            key: const Key('settings_light_palette_dropdown'),
            selected: settings.lightPalette.id,
            palettes: AppPalette.lightPalettes,
            enabled: settings.themeMode != ThemeMode.dark,
            onChanged: settings.setLightPalette,
          ),

          // Dark Theme Palette
          _buildPaletteOption(
            context: context,
            label: l10n.settingsDarkTheme,
            key: const Key('settings_dark_palette_dropdown'),
            selected: settings.darkPalette.id,
            palettes: AppPalette.darkPalettes,
            enabled: settings.themeMode != ThemeMode.light,
            onChanged: settings.setDarkPalette,
          ),
          const Divider(),

          // 2. Suivi
          _SectionHeader(title: l10n.settingsSectionTracking),
          SwitchListTile(
            key: const Key('settings_advanced_tracking'),
            title: Text(l10n.settingsAdvancedTracking),
            subtitle: Text(l10n.settingsAdvancedTrackingSubtitle),
            value: settings.advancedTracking,
            onChanged: settings.setAdvancedTracking,
          ),
          ListTile(
            key: const Key('settings_previous_episodes'),
            title: Text(l10n.settingsPreviousEpisodes),
            subtitle: Text(l10n.settingsPreviousEpisodesSubtitle),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<PreviousEpisodesBehavior>(
                value: settings.previousEpisodes,
                isDense: true,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                onChanged: (val) {
                  if (val != null) settings.setPreviousEpisodes(val);
                },
                style: dropdownStyle,
                alignment: Alignment.centerRight,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: [
                  DropdownMenuItem(
                    value: PreviousEpisodesBehavior.ask,
                    child: Text(l10n.settingsPreviousEpisodesAsk),
                  ),
                  DropdownMenuItem(
                    value: PreviousEpisodesBehavior.all,
                    child: Text(l10n.settingsPreviousEpisodesAll),
                  ),
                  DropdownMenuItem(
                    value: PreviousEpisodesBehavior.one,
                    child: Text(l10n.settingsPreviousEpisodesOne),
                  ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            key: const Key('settings_hide_non_released'),
            title: Text(l10n.settingsHideNonReleased),
            subtitle: Text(l10n.settingsHideNonReleasedSubtitle),
            value: settings.hideNonReleased,
            onChanged: settings.setHideNonReleased,
          ),
          ListTile(
            key: const Key('settings_watch_providers_country_tile'),
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
          SwitchListTile(
            key: const Key('settings_swipe_mode_switch'),
            title: Text(l10n.swiperSettingTitle),
            subtitle: Text(l10n.swiperSettingSubtitle),
            value: settings.isSwipeModeEnabled,
            onChanged: settings.setSwipeModeEnabled,
          ),
          if (settings.isSwipeModeEnabled) const _SwipeResetTile(),
          const Divider(),

          // 3. À propos
          _SectionHeader(title: l10n.settingsSectionAbout),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: l10n.appTitle,
            applicationVersion: appVersion,
            aboutBoxChildren: [
              Text(l10n.settingsAboutDescription),
              const SizedBox(height: 8),
              Text(l10n.settingsAboutJustWatch),
              const SizedBox(height: 8),
              Text(l10n.settingsAboutTmdb),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedOption<T>({
    required BuildContext context,
    required String label,
    required Key key,
    required T selected,
    required List<AppSegment<T>> segments,
    required ValueChanged<T> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: !enabled,
              child: AppSegmented<T>(
                key: key,
                segments: segments,
                selected: selected,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Every palette of one brightness, as wrapping chips: the core palettes
  /// of the design first, then the preserved legacy ones.
  Widget _buildPaletteOption({
    required BuildContext context,
    required String label,
    required Key key,
    required AppPaletteId selected,
    required List<AppPalette> palettes,
    required ValueChanged<AppPaletteId> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final l10n = context.l10n;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: !enabled,
              child: Wrap(
                key: key,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final palette in palettes)
                    ChoiceChip(
                      key: Key('settings_palette_${palette.id.name}'),
                      avatar: _PaletteSwatch(palette: palette),
                      label: Text(paletteName(l10n, palette.id)),
                      selected: palette.id == selected,
                      showCheckmark: false,
                      onSelected: (_) => onChanged(palette.id),
                    ),
                ],
              ),
            ),
          ],
        ),
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
}

class _SwipeResetTile extends StatefulWidget {
  const _SwipeResetTile();

  @override
  State<_SwipeResetTile> createState() => _SwipeResetTileState();
}

class _SwipeResetTileState extends State<_SwipeResetTile> {
  int _discardedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      if (locator.isRegistered<MediaRepository>()) {
        final decisions = await locator<MediaRepository>().getSwipeDecisions();
        if (mounted) {
          setState(() {
            _discardedCount = decisions
                .where((d) => d.decision == 'discarded')
                .length;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmReset(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.swiperResetConfirmTitle),
        content: Text(l10n.swiperResetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('settings_swipe_reset_confirm'),
            onPressed: () async {
              Navigator.pop(ctx);
              if (locator.isRegistered<MediaRepository>()) {
                await locator<MediaRepository>().clearAllSwipeDecisions();
              }
              if (mounted) {
                setState(() => _discardedCount = 0);
                showAppMessage(l10n.swiperResetSuccessToast);
              }
            },
            child: Text(l10n.swiperResetButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const Key('settings_swipe_reset_tile'),
      leading: const Icon(Icons.swipe),
      title: Text(l10n.swiperTitle),
      subtitle: Text(
        _isLoading ? '…' : l10n.swiperDiscardedCount(_discardedCount),
      ),
      trailing: TextButton(
        key: const Key('settings_swipe_reset_button'),
        onPressed: () => _confirmReset(context),
        child: Text(l10n.swiperResetButton),
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
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Preview of a palette: its page background with a recessed surface dot.
class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.bg,
        shape: BoxShape.circle,
        border: Border.all(color: context.appColors.stateOutline),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: palette.surface2,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
