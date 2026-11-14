import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_theme.dart';

/// Stable identifier of a palette, persisted in the user's preferences.
///
/// Never rename a value: [name] is what is written to disk. Add new palettes
/// at will; an identifier that is no longer known falls back to the default
/// of its brightness (see [AppPalette.fromStorageId]).
enum AppPaletteId {
  papier(Brightness.light),
  sable(Brightness.light),
  brume(Brightness.light),
  encre(Brightness.dark),
  nuit(Brightness.dark),
  oled(Brightness.dark);

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
       film = const Color(0xFFB23A0A),
       filmBg = const Color(0xFFFBE7DC),
       serie = const Color(0xFF1D4ED8),
       serieBg = const Color(0xFFDFE7FB),
       onSerie = const Color(0xFFFFFFFF),
       livre = const Color(0xFF44700C),
       livreBg = const Color(0xFFE5EFD6),
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
       film = const Color(0xFFFB8A4C),
       filmBg = const Color(0xFF3A2418),
       serie = const Color(0xFF8AB0FF),
       serieBg = const Color(0xFF1C2640),
       onSerie = const Color(0xFF121110),
       livre = const Color(0xFFA8CC6E),
       livreBg = const Color(0xFF25301A),
       duo = const Color(0xFFB99BFF),
       duoBg = const Color(0xFF2A2140),
       danger = const Color(0xFFFF9B8A),
       onDanger = const Color(0xFF121110),
       success = const Color(0xFF86D69C),
       warning = const Color(0xFFF2C063);

  static const papier = AppPalette._light(
    id: AppPaletteId.papier,
    bg: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFECE8DF),
    border: Color(0xFFDED8CC),
  );

  static const sable = AppPalette._light(
    id: AppPaletteId.sable,
    bg: Color(0xFFF3EDE2),
    surface: Color(0xFFFFFCF6),
    surface2: Color(0xFFE8DFCF),
    border: Color(0xFFDCD0BC),
  );

  static const brume = AppPalette._light(
    id: AppPaletteId.brume,
    bg: Color(0xFFEEF1F4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE1E6EC),
    border: Color(0xFFD3DAE2),
  );

  static const encre = AppPalette._dark(
    id: AppPaletteId.encre,
    bg: Color(0xFF121110),
    surface: Color(0xFF1C1B19),
    surface2: Color(0xFF292723),
    border: Color(0xFF36332E),
  );

  static const nuit = AppPalette._dark(
    id: AppPaletteId.nuit,
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

  /// Every palette, light ones first, in the order of the design.
  static const List<AppPalette> values = [
    papier,
    sable,
    brume,
    encre,
    nuit,
    oled,
  ];

  static const AppPalette defaultLight = papier;
  static const AppPalette defaultDark = encre;

  static List<AppPalette> get lightPalettes =>
      values.where((p) => p.brightness == Brightness.light).toList();

  static List<AppPalette> get darkPalettes =>
      values.where((p) => p.brightness == Brightness.dark).toList();

  static AppPalette defaultFor(Brightness brightness) =>
      brightness == Brightness.dark ? defaultDark : defaultLight;

  static AppPalette of(AppPaletteId id) => values.firstWhere((p) => p.id == id);

  /// Palette stored under [storageId] for [brightness].
  ///
  /// Falls back to the default palette of [brightness] when the value is
  /// missing, unknown, or belongs to the other brightness.
  static AppPalette fromStorageId(String? storageId, Brightness brightness) {
    for (final palette in values) {
      if (palette.id.name == storageId && palette.brightness == brightness) {
        return palette;
      }
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
  final Color film;
  final Color filmBg;
  final Color serie;
  final Color serieBg;

  /// Content laid on a [serie] fill.
  final Color onSerie;
  final Color livre;
  final Color livreBg;

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
    film: film,
    filmBg: filmBg,
    serie: serie,
    serieBg: serieBg,
    onSerie: onSerie,
    livre: livre,
    livreBg: livreBg,
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

  final Color film;
  final Color filmBg;
  final Color serie;
  final Color serieBg;
  final Color onSerie;
  final Color livre;
  final Color livreBg;
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
    required this.film,
    required this.filmBg,
    required this.serie,
    required this.serieBg,
    required this.onSerie,
    required this.livre,
    required this.livreBg,
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
    Color? film,
    Color? filmBg,
    Color? serie,
    Color? serieBg,
    Color? onSerie,
    Color? livre,
    Color? livreBg,
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
      film: film ?? this.film,
      filmBg: filmBg ?? this.filmBg,
      serie: serie ?? this.serie,
      serieBg: serieBg ?? this.serieBg,
      onSerie: onSerie ?? this.onSerie,
      livre: livre ?? this.livre,
      livreBg: livreBg ?? this.livreBg,
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
      film: Color.lerp(film, other.film, t)!,
      filmBg: Color.lerp(filmBg, other.filmBg, t)!,
      serie: Color.lerp(serie, other.serie, t)!,
      serieBg: Color.lerp(serieBg, other.serieBg, t)!,
      onSerie: Color.lerp(onSerie, other.onSerie, t)!,
      livre: Color.lerp(livre, other.livre, t)!,
      livreBg: Color.lerp(livreBg, other.livreBg, t)!,
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
