import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_theme.dart';

/// Stable identifier of a palette, persisted in the user's preferences.
///
/// Never rename a value: [name] is what is written to disk. Add new palettes
/// at will; an identifier that is no longer known falls back to the default
/// of its brightness (see [AppPalette.fromStorageId]).
enum AppPaletteId {
  paper(Brightness.light),
  sand(Brightness.light),
  mist(Brightness.light),
  ink(Brightness.dark),
  night(Brightness.dark),
  oled(Brightness.dark),

  // Preserved legacy theme palettes:
  classicLight(Brightness.light),
  parchment(Brightness.light),
  mint(Brightness.light),
  solarizedLight(Brightness.light),
  pinky(Brightness.light),
  classicDark(Brightness.dark),
  slate(Brightness.dark),
  midnight(Brightness.dark),
  espresso(Brightness.dark);

  const AppPaletteId(this.brightness);

  final Brightness brightness;
}

/// Design tokens of the "ink on paper" design.
///
/// A palette only changes the surfaces ([bg], [surface], [surface2],
/// [border]); every other token depends on the brightness alone. Values come
/// from the design prototype and must not drift from it.
@immutable
class AppPalette {
  const AppPalette._light({
    required this.id,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
  }) : brightness = Brightness.light,
       text = const Color(0xFF1B1A17),
       text2 = const Color(0xFF5C584F),
       primary = const Color(0xFF1B1A17),
       onPrimary = const Color(0xFFFFFFFF),
       movie = const Color(0xFFB23A0A),
       movieBg = const Color(0xFFFBE7DC),
       series = const Color(0xFF1D4ED8),
       seriesBg = const Color(0xFFDFE7FB),
       onSeries = const Color(0xFFFFFFFF),
       book = const Color(0xFF44700C),
       bookBg = const Color(0xFFE5EFD6),
       duo = const Color(0xFF7C3AED),
       duoBg = const Color(0xFFEDE4FD),
       danger = const Color(0xFFB42318),
       onDanger = const Color(0xFFFFFFFF),
       // Darker than the prototype (#1E7A3A) to reach 4.5:1 on every surface2.
       success = const Color(0xFF1A6B33),
       warning = const Color(0xFF7A4F00);

  const AppPalette._dark({
    required this.id,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
  }) : brightness = Brightness.dark,
       text = const Color(0xFFF3F0EA),
       text2 = const Color(0xFFABA59A),
       primary = const Color(0xFFF3F0EA),
       onPrimary = const Color(0xFF121110),
       movie = const Color(0xFFFB8A4C),
       movieBg = const Color(0xFF3A2418),
       series = const Color(0xFF8AB0FF),
       seriesBg = const Color(0xFF1C2640),
       onSeries = const Color(0xFF121110),
       book = const Color(0xFFA8CC6E),
       bookBg = const Color(0xFF25301A),
       duo = const Color(0xFFB99BFF),
       duoBg = const Color(0xFF2A2140),
       danger = const Color(0xFFFF9B8A),
       onDanger = const Color(0xFF121110),
       success = const Color(0xFF86D69C),
       warning = const Color(0xFFF2C063);

  // Core V1 Design Palettes
  static const paper = AppPalette._light(
    id: AppPaletteId.paper,
    bg: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECE8DF),
    border: Color(0xFFDED8CC),
  );

  static const sand = AppPalette._light(
    id: AppPaletteId.sand,
    bg: Color(0xFFF3EDE2),
    surface: Color(0xFFFFFCF6),
    surface2: Color(0xFFE8DFCF),
    border: Color(0xFFDCD0BC),
  );

  static const mist = AppPalette._light(
    id: AppPaletteId.mist,
    bg: Color(0xFFEEF1F4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE1E6EC),
    border: Color(0xFFD3DAE2),
  );

  static const ink = AppPalette._dark(
    id: AppPaletteId.ink,
    bg: Color(0xFF121110),
    surface: Color(0xFF1C1B19),
    surface2: Color(0xFF292723),
    border: Color(0xFF36332E),
  );

  static const night = AppPalette._dark(
    id: AppPaletteId.night,
    bg: Color(0xFF0E1320),
    surface: Color(0xFF161D2E),
    surface2: Color(0xFF212A3F),
    border: Color(0xFF2C3650),
  );

  static const oled = AppPalette._dark(
    id: AppPaletteId.oled,
    bg: Color(0xFF000000),
    surface: Color(0xFF0D0D0D),
    surface2: Color(0xFF1A1A1A),
    border: Color(0xFF262626),
  );

  // Preserved Previous Theme Styles (Light)
  static const classicLight = AppPalette._light(
    id: AppPaletteId.classicLight,
    bg: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECEFF1),
    border: Color(0xFFCFD8DC),
  );

  static const parchment = AppPalette._light(
    id: AppPaletteId.parchment,
    bg: Color(0xFFFBF0D9),
    surface: Color(0xFFFFFDF5),
    surface2: Color(0xFFF0E4C8),
    border: Color(0xFFE2D6C0),
  );

  static const mint = AppPalette._light(
    id: AppPaletteId.mint,
    bg: Color(0xFFF1F8F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE0EFE4),
    border: Color(0xFFC8E2CF),
  );

  static const solarizedLight = AppPalette._light(
    id: AppPaletteId.solarizedLight,
    bg: Color(0xFFFDF6E3),
    surface: Color(0xFFFFFDF5),
    surface2: Color(0xFFEEE8D5),
    border: Color(0xFFD3CBB7),
  );

  static const pinky = AppPalette._light(
    id: AppPaletteId.pinky,
    bg: Color(0xFFFDF2F4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF8DAE0),
    border: Color(0xFFEDB9C5),
  );

  // Preserved Previous Theme Styles (Dark)
  static const classicDark = AppPalette._dark(
    id: AppPaletteId.classicDark,
    bg: Color(0xFF1C1B1F),
    surface: Color(0xFF2B2930),
    surface2: Color(0xFF36343C),
    border: Color(0xFF49454F),
  );

  static const slate = AppPalette._dark(
    id: AppPaletteId.slate,
    bg: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surface2: Color(0xFF283446),
    border: Color(0xFF384556),
  );

  static const midnight = AppPalette._dark(
    id: AppPaletteId.midnight,
    bg: Color(0xFF0B0F19),
    surface: Color(0xFF111827),
    surface2: Color(0xFF1F2937),
    border: Color(0xFF374151),
  );

  static const espresso = AppPalette._dark(
    id: AppPaletteId.espresso,
    bg: Color(0xFF1C130E),
    surface: Color(0xFF2B1D16),
    surface2: Color(0xFF3D2B22),
    border: Color(0xFF543E33),
  );

  /// The six core palettes of the design.
  static const List<AppPalette> coreValues = [
    paper,
    sand,
    mist,
    ink,
    night,
    oled,
  ];

  /// Every available palette, including preserved legacy styles.
  static const List<AppPalette> values = [
    paper,
    sand,
    mist,
    ink,
    night,
    oled,
    classicLight,
    parchment,
    mint,
    solarizedLight,
    pinky,
    classicDark,
    slate,
    midnight,
    espresso,
  ];

  static const AppPalette defaultLight = paper;
  static const AppPalette defaultDark = ink;
  static const AppPalette defaultLightPalette = paper;
  static const AppPalette defaultDarkPalette = ink;

  static List<AppPalette> get lightPalettes =>
      values.where((p) => p.brightness == Brightness.light).toList();

  static List<AppPalette> get darkPalettes =>
      values.where((p) => p.brightness == Brightness.dark).toList();

  static AppPalette defaultFor(Brightness brightness) =>
      brightness == Brightness.dark ? defaultDarkPalette : defaultLightPalette;

  static AppPalette of(AppPaletteId id) => values.firstWhere((p) => p.id == id);

  /// Palette stored under [storageId] for [brightness].
  ///
  /// Falls back to the default palette of [brightness] when the value is
  /// missing, unknown, or belongs to the other brightness.
  static AppPalette fromStorageId(String? storageId, Brightness brightness) {
    if (storageId == null) return defaultFor(brightness);
    for (final palette in values) {
      if (palette.id.name == storageId && palette.brightness == brightness) {
        return palette;
      }
    }
    // Backward-compatibility aliases for legacy storage IDs:
    if (storageId == 'defaultLight' && brightness == Brightness.light) {
      return classicLight;
    }
    if (storageId == 'defaultDark' && brightness == Brightness.dark) {
      return classicDark;
    }
    return defaultFor(brightness);
  }

  final AppPaletteId id;
  final Brightness brightness;

  /// Page background ("paper").
  final Color bg;

  /// Cards, sheets, bars.
  final Color surface;

  /// Recessed or neutral filled areas (tracks, placeholders, chips).
  final Color surface2;

  /// Primary text ("ink").
  final Color text;

  /// Secondary text. Also the outline of state controls (unchecked box,
  /// switch that is off), which need 3:1 against the surfaces: [border] is
  /// decorative only and does not reach it.
  final Color text2;

  /// Decorative hairlines: card outlines, dividers.
  final Color border;

  /// Primary color: the ink. Never a hue.
  final Color primary;
  final Color onPrimary;

  /// One color per media type, with its tinted background.
  final Color movie;
  final Color movieBg;
  final Color series;
  final Color seriesBg;

  /// Content laid on a [series] fill.
  final Color onSeries;
  final Color book;
  final Color bookBg;

  /// "Ensemble" (watching together).
  final Color duo;
  final Color duoBg;

  /// Semantic states. Media colors must never be used for a state.
  final Color danger;
  final Color onDanger;
  final Color success;

  /// Not part of the design prototype: kept for the existing screens that
  /// signal "not released yet" / "offline" until they are redesigned.
  final Color warning;

  /// Outline of a state control in its "off" state (3:1 minimum).
  Color get stateOutline => text2;

  ThemeData toThemeData() => buildAppTheme(this);

  AppThemeExtension toExtension() => AppThemeExtension(
    bg: bg,
    surface: surface,
    surface2: surface2,
    text: text,
    text2: text2,
    border: border,
    primary: primary,
    onPrimary: onPrimary,
    movie: movie,
    movieBg: movieBg,
    series: series,
    seriesBg: seriesBg,
    onSeries: onSeries,
    book: book,
    bookBg: bookBg,
    duo: duo,
    duoBg: duoBg,
    danger: danger,
    onDanger: onDanger,
    success: success,
    warning: warning,
  );
}

/// Design tokens exposed to widgets through `context.appColors`.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color text2;
  final Color border;
  final Color primary;
  final Color onPrimary;

  final Color movie;
  final Color movieBg;
  final Color series;
  final Color seriesBg;
  final Color onSeries;
  final Color book;
  final Color bookBg;

  final Color duo;
  final Color duoBg;

  final Color danger;
  final Color onDanger;
  final Color success;
  final Color warning;

  const AppThemeExtension({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.text2,
    required this.border,
    required this.primary,
    required this.onPrimary,
    this.movie = const Color(0xFFB23A0A),
    this.movieBg = const Color(0xFFFBE7DC),
    this.series = const Color(0xFF1D4ED8),
    this.seriesBg = const Color(0xFFDFE7FB),
    this.onSeries = const Color(0xFFFFFFFF),
    this.book = const Color(0xFF44700C),
    this.bookBg = const Color(0xFFE5EFD6),
    required this.duo,
    required this.duoBg,
    required this.danger,
    required this.onDanger,
    required this.success,
    required this.warning,
  });

  // Roles used by the screens that are not redesigned yet. They all resolve
  // to design tokens, so that no screen keeps a color of its own.

  /// Outline of a state control in its "off" state (3:1 minimum).
  Color get stateOutline => text2;

  /// Error text and icons.
  Color get error => danger;

  /// "Liked" heart.
  Color get likeHeart => danger;

  /// Rating star and rating chip background (content: [badgeText]).
  Color get ratingStar => primary;

  /// "In my watchlist" marker.
  Color get onWatchlist => success;

  /// Badge laid on a poster (content: [badgeText]).
  Color get badgeBg => primary;

  /// Badge of a title that is fully seen (content: [badgeText]).
  Color get seenBadge => success;

  /// Content of [badgeBg], [seenBadge] and [ratingStar] fills.
  Color get badgeText => onPrimary;

  /// Neutral fill shown while an image is missing or loading.
  Color get placeholder => surface2;

  @override
  AppThemeExtension copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? text,
    Color? text2,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? movie,
    Color? movieBg,
    Color? series,
    Color? seriesBg,
    Color? onSeries,
    Color? book,
    Color? bookBg,
    Color? duo,
    Color? duoBg,
    Color? danger,
    Color? onDanger,
    Color? success,
    Color? warning,
  }) {
    return AppThemeExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      movie: movie ?? this.movie,
      movieBg: movieBg ?? this.movieBg,
      series: series ?? this.series,
      seriesBg: seriesBg ?? this.seriesBg,
      onSeries: onSeries ?? this.onSeries,
      book: book ?? this.book,
      bookBg: bookBg ?? this.bookBg,
      duo: duo ?? this.duo,
      duoBg: duoBg ?? this.duoBg,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      movie: Color.lerp(movie, other.movie, t)!,
      movieBg: Color.lerp(movieBg, other.movieBg, t)!,
      series: Color.lerp(series, other.series, t)!,
      seriesBg: Color.lerp(seriesBg, other.seriesBg, t)!,
      onSeries: Color.lerp(onSeries, other.onSeries, t)!,
      book: Color.lerp(book, other.book, t)!,
      bookBg: Color.lerp(bookBg, other.bookBg, t)!,
      duo: Color.lerp(duo, other.duo, t)!,
      duoBg: Color.lerp(duoBg, other.duoBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appColors =>
      Theme.of(this).extension<AppThemeExtension>()!;
}

/// Black or white, whichever reads better on [background].
///
/// For colors that have no matching `on*` token.
Color contrastingForeground(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

/// Default light palette wrapper for convenience and test compatibility.
class DefaultLightPalette {
  const DefaultLightPalette();

  AppPalette get palette => AppPalette.defaultLight;

  ThemeData toThemeData() => AppPalette.defaultLight.toThemeData();
}

/// Default dark palette wrapper for convenience and test compatibility.
class DefaultDarkPalette {
  const DefaultDarkPalette();

  AppPalette get palette => AppPalette.defaultDark;

  ThemeData toThemeData() => AppPalette.defaultDark.toThemeData();
}
