import 'dart:io';

import 'package:flutter/foundation.dart';

/// Forces [loadNetworkImages] to true under `flutter test`. Set by the
/// screenshot tool (`test/screenshots/`), which serves images locally.
@visibleForTesting
bool debugForceNetworkImages = false;

/// Whether TMDB images should be loaded from the network.
///
/// False in widget tests, whose HTTP client answers every request with an
/// error, unless [debugForceNetworkImages] is set.
bool get loadNetworkImages =>
    debugForceNetworkImages ||
    !Platform.environment.containsKey('FLUTTER_TEST');
