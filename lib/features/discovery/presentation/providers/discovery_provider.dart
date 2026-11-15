import 'package:flutter/foundation.dart';

/// Modes of the Discover tab.
enum DiscoverMode { explore, swipe }

/// Whether books are offered in Discover (type chip, search hint).
///
/// Off until the book search lands (#323): single switch.
const bool kDiscoverShowBooks = false;

/// UI state of the Discover tab; data stays in `SearchProvider`.
class DiscoveryProvider extends ChangeNotifier {
  DiscoveryProvider();

  DiscoverMode _mode = DiscoverMode.explore;

  DiscoverMode get mode => _mode;

  void setMode(DiscoverMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }
}
