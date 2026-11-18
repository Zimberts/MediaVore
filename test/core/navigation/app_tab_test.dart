import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/navigation/app_tab.dart';

void main() {
  group('AppTab', () {
    test('should list the tabs in the order of the design', () {
      expect(AppTab.values, [
        AppTab.home,
        AppTab.discover,
        AppTab.library,
        AppTab.together,
        AppTab.me,
      ]);
      expect(AppTab.initial, AppTab.home);
    });

    test('should show Together as a tab unless the switch is turned off', () {
      expect(kShowTogetherTab, isTrue);
      expect(AppTab.visibleTabs, AppTab.values);
    });

    test('should have a French and an English label for every tab', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final fr = lookupAppLocalizations(const Locale('fr'));

      expect(AppTab.values.map((tab) => tab.label(en)), [
        'Home',
        'Discover',
        'Library',
        'Together',
        'Me',
      ]);
      expect(AppTab.values.map((tab) => tab.label(fr)), [
        'Accueil',
        'Découvrir',
        'Bibliothèque',
        'Ensemble',
        'Moi',
      ]);
    });

    test('should give every tab distinct icons', () {
      expect(AppTab.values.map((tab) => tab.icon).toSet(), hasLength(5));
      expect(
        AppTab.values.map((tab) => tab.selectedIcon).toSet(),
        hasLength(5),
      );
    });
  });
}
