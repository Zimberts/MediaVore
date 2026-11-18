import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mediavore/core/theme/app_typography.dart';

/// License texts of the bundled fonts, by font family.
const Map<String, String> fontLicenseAssets = {
  AppFonts.heading: 'assets/fonts/bricolage_grotesque/OFL.txt',
  AppFonts.body: 'assets/fonts/inter/OFL.txt',
};

/// Lists the SIL Open Font License of each bundled font on the licenses page.
void registerFontLicenses({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    for (final entry in fontLicenseAssets.entries) {
      final text = await (bundle ?? rootBundle).loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
