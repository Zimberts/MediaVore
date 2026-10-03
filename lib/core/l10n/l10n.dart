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
