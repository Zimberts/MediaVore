import 'package:flutter/widgets.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';

export 'package:mediavore/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// Localized strings for this context, in English when no
  /// [AppLocalizations] delegate is in scope (e.g. bare widget tests).
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      fallbackLocalizations;
}

/// Strings in [fallbackAppLanguage], for code without a [BuildContext].
AppLocalizations get fallbackLocalizations =>
    lookupAppLocalizations(fallbackAppLanguage.locale);

/// Localized display name of a palette.
String paletteName(AppLocalizations l10n, AppPaletteId id) {
  switch (id) {
    case AppPaletteId.paper:
      return l10n.paletteNamePaper;
    case AppPaletteId.sand:
      return l10n.paletteNameSand;
    case AppPaletteId.mist:
      return l10n.paletteNameMist;
    case AppPaletteId.ink:
      return l10n.paletteNameInk;
    case AppPaletteId.night:
      return l10n.paletteNameNight;
    case AppPaletteId.oled:
      return l10n.paletteNameOled;
    case AppPaletteId.defaultLight:
      return l10n.paletteNameDefaultLight;
    case AppPaletteId.parchment:
      return l10n.paletteNameParchment;
    case AppPaletteId.mint:
      return l10n.paletteNameMint;
    case AppPaletteId.solarizedLight:
      return l10n.paletteNameSolarizedLight;
    case AppPaletteId.pinky:
      return l10n.paletteNamePinky;
    case AppPaletteId.defaultDark:
      return l10n.paletteNameDefaultDark;
    case AppPaletteId.slate:
      return l10n.paletteNameSlate;
    case AppPaletteId.midnight:
      return l10n.paletteNameMidnight;
    case AppPaletteId.espresso:
      return l10n.paletteNameEspresso;
  }
}

/// Localized TMDB `status` (TMDB always returns it in English).
String localizedMediaStatus(AppLocalizations l10n, String status) {
  switch (status.toLowerCase()) {
    case 'released':
      return l10n.statusReleased;
    case 'returning series':
      return l10n.statusReturning;
    case 'ended':
      return l10n.statusEnded;
    case 'canceled':
    case 'cancelled':
      return l10n.statusCanceled;
    case 'in production':
      return l10n.statusInProduction;
    case 'post production':
      return l10n.statusPostProduction;
    case 'planned':
      return l10n.statusPlanned;
    case 'rumored':
      return l10n.statusRumored;
    case 'pilot':
      return l10n.statusPilot;
  }
  return status;
}
