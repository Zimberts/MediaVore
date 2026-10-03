import 'package:flutter/widgets.dart';
import 'package:mediavore/core/l10n/app_language.dart';
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
