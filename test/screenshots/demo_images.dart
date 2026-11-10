/// Locally generated artwork for the screenshot catalog, and an [HttpOverrides]
/// that serves it in place of `image.tmdb.org`.
///
/// Posters are drawn with `dart:ui` (gradient + title), so no third-party
/// artwork is downloaded or committed.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'demo_catalog.dart';

/// PNG bytes by TMDB image path (e.g. `/demo/poster/movie-129.png`).
typedef DemoImages = Map<String, Uint8List>;

const _palette = <Color>[
  Color(0xFF8E2C48),
  Color(0xFF2C5E8E),
  Color(0xFF3E7D4F),
  Color(0xFFB0662A),
  Color(0xFF5B3D8F),
  Color(0xFF1F7A7A),
  Color(0xFF9C3B2E),
  Color(0xFF44546A),
];

Color _color(int seed, [int shift = 0]) =>
    _palette[(seed + shift).abs() % _palette.length];

Future<Uint8List> _render(
  int width,
  int height,
  void Function(Canvas canvas, Size size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas, Size(width.toDouble(), height.toDouble()));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void _text(
  Canvas canvas,
  String text,
  Offset at,
  double maxWidth,
  TextStyle style, {
  TextAlign align = TextAlign.left,
  int maxLines = 4,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  painter.paint(canvas, at);
}

void _gradient(Canvas canvas, Size size, Color a, Color b) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, Color.lerp(b, const Color(0xFF000000), 0.55)!],
      ).createShader(rect),
  );
  // A few soft discs for texture.
  final disc = Paint()..color = const Color(0x22FFFFFF);
  canvas.drawCircle(
    Offset(size.width * .85, size.height * .2),
    size.width * .35,
    disc,
  );
  canvas.drawCircle(
    Offset(size.width * .1, size.height * .75),
    size.width * .25,
    disc,
  );
}

Future<Uint8List> _poster(DemoMedia m, String lang) =>
    _render(300, 450, (c, s) {
      _gradient(c, s, _color(m.id), _color(m.id, 3));
      _text(
        c,
        m.title(lang).toUpperCase(),
        const Offset(22, 250),
        256,
        const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 30,
          height: 1.05,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFFFFF),
        ),
      );
      _text(
        c,
        '${m.year}${m.isTv ? ' · SÉRIE' : ''}',
        const Offset(22, 410),
        256,
        const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          letterSpacing: 2,
          color: Color(0xCCFFFFFF),
        ),
      );
    });

Future<Uint8List> _backdrop(DemoMedia m, String lang) =>
    _render(780, 440, (c, s) {
      _gradient(c, s, _color(m.id, 3), _color(m.id));
      _text(
        c,
        m.title(lang),
        const Offset(40, 300),
        700,
        const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 44,
          fontWeight: FontWeight.w300,
          color: Color(0x55FFFFFF),
        ),
        maxLines: 1,
      );
    });

Future<Uint8List> _portrait(DemoPerson p) => _render(200, 300, (c, s) {
  _gradient(c, s, _color(p.id, 5), _color(p.id, 1));
  final initials = p.name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0])
      .join();
  _text(
    c,
    initials,
    const Offset(0, 105),
    200,
    const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 72,
      fontWeight: FontWeight.w700,
      color: Color(0xEEFFFFFF),
    ),
    align: TextAlign.center,
    maxLines: 1,
  );
});

Future<Uint8List> _logo(String letter, Color color) => _render(92, 92, (c, s) {
  c.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(18)),
    Paint()..color = color,
  );
  _text(
    c,
    letter,
    const Offset(0, 18),
    92,
    const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 48,
      fontWeight: FontWeight.w900,
      color: Color(0xFFFFFFFF),
    ),
    align: TextAlign.center,
    maxLines: 1,
  );
});

/// Renders every image the demo catalog refers to. Needs real async (call it
/// from `tester.runAsync`) and the Roboto font loaded for legible titles.
Future<DemoImages> renderDemoImages(String lang) async {
  final images = <String, Uint8List>{};
  for (final m in demoCatalog) {
    images[m.posterPath] = await _poster(m, lang);
    images[m.backdropPath] = await _backdrop(m, lang);
  }
  for (final p in demoPeople) {
    images['/demo/person/${p.id}.png'] = await _portrait(p);
  }
  images['/demo/logo/netflix.png'] = await _logo('N', const Color(0xFFB20710));
  images['/demo/logo/disney.png'] = await _logo('D', const Color(0xFF113CCF));
  images['/demo/logo/prime.png'] = await _logo('P', const Color(0xFF00A8E1));
  return images;
}

/// Serves [images] for any `image.tmdb.org/t/p/<size><path>` URL; every other
/// HTTP request gets a 404, so nothing leaves the machine.
class DemoHttpOverrides extends HttpOverrides {
  DemoHttpOverrides(this.images);

  final DemoImages images;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _DemoHttpClient(images);
}

Uint8List? _lookup(DemoImages images, Uri url) {
  // /t/p/w500/demo/poster/movie-129.png -> /demo/poster/movie-129.png
  final i = url.path.indexOf('/demo/');
  return i < 0 ? null : images[url.path.substring(i)];
}

class _DemoHttpClient implements HttpClient {
  _DemoHttpClient(this.images);

  final DemoImages images;

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _DemoRequest(_lookup(images, url));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _DemoRequest implements HttpClientRequest {
  _DemoRequest(this.body);

  final Uint8List? body;

  @override
  final HttpHeaders headers = _DemoHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _DemoResponse(body);

  @override
  Future<HttpClientResponse> get done => close();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _DemoResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _DemoResponse(this.body)
    : super(Stream<List<int>>.fromIterable([if (body != null) body]));

  final Uint8List? body;

  @override
  int get statusCode => body == null ? 404 : 200;

  @override
  String get reasonPhrase => body == null ? 'Not Found' : 'OK';

  @override
  int get contentLength => body?.length ?? 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  final HttpHeaders headers = _DemoHeaders(contentType: 'image/png');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _DemoHeaders implements HttpHeaders {
  _DemoHeaders({String? contentType})
    : _values = {
        if (contentType != null) 'content-type': [contentType],
        'cache-control': ['max-age=31536000'],
      };

  final Map<String, List<String>> _values;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      _values.putIfAbsent(name.toLowerCase(), () => []).add('$value');

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _values[name.toLowerCase()] = ['$value'];

  @override
  String? value(String name) => _values[name.toLowerCase()]?.first;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
