import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// One light and one dark palette: enough to exercise both brightnesses.
const List<AppPalette> testPalettes = [AppPalette.paper, AppPalette.ink];

/// App shell for widget tests: real theme (tokens) and localizations.
///
/// [builder] is forwarded to `MaterialApp.builder`.
Widget testApp(
  Widget child, {
  AppPalette palette = AppPalette.paper,
  Locale locale = const Locale('en'),
  TransitionBuilder? builder,
  bool scaffold = true,
}) {
  return MaterialApp(
    theme: palette.toThemeData(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: builder,
    home: scaffold ? Scaffold(body: Center(child: child)) : child,
  );
}

/// Image of a single [color], decoded synchronously.
ui.Image solidImage(Color color, {int width = 20, int height = 30}) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  return recorder.endRecording().toImageSync(width, height);
}

/// Provider that delivers [image] in the first frame, without any I/O.
class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider(this.image);

  final ui.Image image;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<TestImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    TestImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    SynchronousFuture<ImageInfo>(ImageInfo(image: image.clone())),
  );
}
