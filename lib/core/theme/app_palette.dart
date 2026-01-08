import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final AppPalette palette;

  AppTheme({
    required this.name,
    required this.palette,
  });
}

final List<AppTheme> lightThemes = [
  AppTheme(name: 'Default Light', palette: DefaultLightPalette()),
  AppTheme(name: 'Parchment', palette: ParchmentPalette()),
  AppTheme(name: 'Mint', palette: MintPalette()),
  AppTheme(name: 'Solarized', palette: SolarizedLightPalette()),
  AppTheme(name: 'Pinky', palette: PinkyPalette()),
];

final List<AppTheme> darkThemes = [
  AppTheme(name: 'Default Dark', palette: DefaultDarkPalette()),
  AppTheme(name: 'Slate', palette: SlatePalette()),
  AppTheme(name: 'Midnight', palette: MidnightPalette()),
  AppTheme(name: 'Espresso', palette: EspressoPalette()),
];

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color onWatchlist;
  final Color likeHeart;
  final Color ratingStar;
  final Color visualSelection;
  final Color logicFlow;
  final Color dataValues;
  final Color constants;
  final Color functions;
  final Color structural;
  final Color comments;
  
  // Badge colors
  final Color badgeBg;
  final Color badgeBgSeen;
  final Color badgeText;

  // Semantic/Utility colors
  final Color warning;
  final Color error;
  final Color success;
  final Color info;
  final Color placeholder;

  const AppThemeExtension({
    required this.onWatchlist,
    required this.likeHeart,
    required this.ratingStar,
    required this.visualSelection,
    required this.logicFlow,
    required this.dataValues,
    required this.constants,
    required this.functions,
    required this.structural,
    required this.comments,
    required this.badgeBg,
    required this.badgeBgSeen,
    required this.badgeText,
    required this.warning,
    required this.error,
    required this.success,
    required this.info,
    required this.placeholder,
  });

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? onWatchlist,
    Color? likeHeart,
    Color? ratingStar,
    Color? visualSelection,
    Color? logicFlow,
    Color? dataValues,
    Color? constants,
    Color? functions,
    Color? structural,
    Color? comments,
    Color? badgeBg,
    Color? badgeBgSeen,
    Color? badgeText,
    Color? warning,
    Color? error,
    Color? success,
    Color? info,
    Color? placeholder,
  }) {
    return AppThemeExtension(
      onWatchlist: onWatchlist ?? this.onWatchlist,
      likeHeart: likeHeart ?? this.likeHeart,
      ratingStar: ratingStar ?? this.ratingStar,
      visualSelection: visualSelection ?? this.visualSelection,
      logicFlow: logicFlow ?? this.logicFlow,
      dataValues: dataValues ?? this.dataValues,
      constants: constants ?? this.constants,
      functions: functions ?? this.functions,
      structural: structural ?? this.structural,
      comments: comments ?? this.comments,
      badgeBg: badgeBg ?? this.badgeBg,
      badgeBgSeen: badgeBgSeen ?? this.badgeBgSeen,
      badgeText: badgeText ?? this.badgeText,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      success: success ?? this.success,
      info: info ?? this.info,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      onWatchlist: Color.lerp(onWatchlist, other.onWatchlist, t)!,
      likeHeart: Color.lerp(likeHeart, other.likeHeart, t)!,
      ratingStar: Color.lerp(ratingStar, other.ratingStar, t)!,
      visualSelection: Color.lerp(visualSelection, other.visualSelection, t)!,
      logicFlow: Color.lerp(logicFlow, other.logicFlow, t)!,
      dataValues: Color.lerp(dataValues, other.dataValues, t)!,
      constants: Color.lerp(constants, other.constants, t)!,
      functions: Color.lerp(functions, other.functions, t)!,
      structural: Color.lerp(structural, other.structural, t)!,
      comments: Color.lerp(comments, other.comments, t)!,
      badgeBg: Color.lerp(badgeBg, other.badgeBg, t)!,
      badgeBgSeen: Color.lerp(badgeBgSeen, other.badgeBgSeen, t)!,
      badgeText: Color.lerp(badgeText, other.badgeText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      placeholder: Color.lerp(placeholder, other.placeholder, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appColors => Theme.of(this).extension<AppThemeExtension>()!;
}

abstract class AppPalette {
  Brightness get brightness;
  Color get primaryBg;
  Color get surface;
  Color get selectionHighlight;
  Color get statusAccent;
  Color get visualSelection;

  // Navigation / Home Row
  Color get navBg;
  Color get navSelectedIcon;
  Color get navUnselectedIcon;

  // Badges
  Color get badgeBg;
  Color get badgeBgSeen;
  Color get badgeText;

  // Media Specific
  Color get likeHeart;
  Color get ratingStar;
  Color get onWatchlist;

  // Syntax/Data semantic mapping
  Color get logicFlow;
  Color get dataValues;
  Color get constants;
  Color get functions;
  Color get structural;
  Color get comments;

  // Text colors
  Color get primaryText;
  Color get secondaryText;

  // Semantic
  Color get warning => Colors.orange;
  Color get error => Colors.red;
  Color get success => Colors.green;
  Color get info => Colors.blue;
  Color get placeholder => Colors.grey.shade300;

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: primaryBg,
      canvasColor: surface,
      cardColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: statusAccent,
        brightness: brightness,
        primary: logicFlow,
        secondary: statusAccent,
        surface: surface,
        onSurface: primaryText,
        onPrimary: brightness == Brightness.dark ? primaryBg : Colors.white,
        surfaceTint: Colors.transparent,
        error: error,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: primaryText),
        bodyMedium: TextStyle(color: primaryText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: statusAccent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: navSelectedIcon,
        unselectedItemColor: navUnselectedIcon,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: badgeBg,
        textColor: badgeText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
      ),
      extensions: [
        AppThemeExtension(
          onWatchlist: onWatchlist,
          likeHeart: likeHeart,
          ratingStar: ratingStar,
          visualSelection: visualSelection,
          logicFlow: logicFlow,
          dataValues: dataValues,
          constants: constants,
          functions: functions,
          structural: structural,
          comments: comments,
          badgeBg: badgeBg,
          badgeBgSeen: badgeBgSeen,
          badgeText: badgeText,
          warning: warning,
          error: error,
          success: success,
          info: info,
          placeholder: placeholder,
        ),
      ],
    );
  }
}

class SlatePalette extends AppPalette {
  @override Brightness get brightness => Brightness.dark;
  @override Color get primaryBg => const Color(0xFF262626);
  @override Color get surface => const Color(0xFF333333);
  @override Color get selectionHighlight => const Color(0xFF333333);
  @override Color get statusAccent => const Color(0xFFafaf87);
  @override Color get visualSelection => const Color(0xFF5f8700);

  @override Color get navBg => const Color(0xFF333333);
  @override Color get navSelectedIcon => const Color(0xFFafaf87);
  @override Color get navUnselectedIcon => const Color(0xFF666666);

  @override Color get badgeBg => const Color(0xFF5f87d7);
  @override Color get badgeBgSeen => const Color(0xFF5f8700);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFffafaf);
  @override Color get ratingStar => const Color(0xFFffd700);
  @override Color get onWatchlist => const Color(0xFF5f8700);

  @override Color get logicFlow => const Color(0xFF5f87d7);
  @override Color get dataValues => const Color(0xFF87d7ff);
  @override Color get constants => const Color(0xFFffafaf);
  @override Color get functions => const Color(0xFFffd7af);
  @override Color get structural => const Color(0xFFffd700);
  @override Color get comments => const Color(0xFF666666);

  @override Color get primaryText => Colors.white;
  @override Color get secondaryText => Colors.white70;

  @override Color get warning => const Color(0xFFffd7af);
  @override Color get placeholder => const Color(0xFF666666);
}

class DefaultDarkPalette extends AppPalette {
  @override Brightness get brightness => Brightness.dark;
  @override Color get primaryBg => const Color(0xFF121212);
  @override Color get surface => const Color(0xFF1E1E1E);
  @override Color get selectionHighlight => Colors.white12;
  @override Color get statusAccent => Colors.deepPurpleAccent;
  @override Color get visualSelection => Colors.deepPurple;

  @override Color get navBg => const Color(0xFF1E1E1E);
  @override Color get navSelectedIcon => Colors.deepPurpleAccent;
  @override Color get navUnselectedIcon => Colors.grey;

  @override Color get badgeBg => Colors.redAccent;
  @override Color get badgeBgSeen => Colors.greenAccent;
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => Colors.red;
  @override Color get ratingStar => Colors.amber;
  @override Color get onWatchlist => Colors.green;

  @override Color get logicFlow => Colors.blue;
  @override Color get dataValues => Colors.lightBlueAccent;
  @override Color get constants => Colors.redAccent;
  @override Color get functions => Colors.orangeAccent;
  @override Color get structural => Colors.yellowAccent;
  @override Color get comments => Colors.grey;

  @override Color get primaryText => Colors.white;
  @override Color get secondaryText => Colors.white70;

  @override Color get placeholder => Colors.grey.shade800;
}

class DefaultLightPalette extends AppPalette {
  @override Brightness get brightness => Brightness.light;
  @override Color get primaryBg => const Color(0xFFF8F9FA);
  @override Color get surface => Colors.white;
  @override Color get selectionHighlight => Colors.black12;
  @override Color get statusAccent => Colors.deepPurple;
  @override Color get visualSelection => Colors.deepPurple;

  @override Color get navBg => Colors.white;
  @override Color get navSelectedIcon => Colors.deepPurple;
  @override Color get navUnselectedIcon => Colors.grey;

  @override Color get badgeBg => Colors.red;
  @override Color get badgeBgSeen => Colors.green;
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => Colors.red;
  @override Color get ratingStar => Colors.amber;
  @override Color get onWatchlist => Colors.green;

  @override Color get logicFlow => const Color(0xFF005FB8);
  @override Color get dataValues => const Color(0xFF0078D4);
  @override Color get constants => const Color(0xFFD13438);
  @override Color get functions => const Color(0xFFCA5010);
  @override Color get structural => const Color(0xFF986F0B);
  @override Color get comments => Colors.grey.shade600;

  @override Color get primaryText => Colors.black;
  @override Color get secondaryText => Colors.black54;
}

class ParchmentPalette extends AppPalette {
  @override Brightness get brightness => Brightness.light;
  @override Color get primaryBg => const Color(0xFFF5F2E7);
  @override Color get surface => const Color(0xFFEFEBD8);
  @override Color get selectionHighlight => const Color(0xFFE0D9BC);
  @override Color get statusAccent => const Color(0xFF8B4513);
  @override Color get visualSelection => const Color(0xFFD2B48C);

  @override Color get navBg => const Color(0xFFEFEBD8);
  @override Color get navSelectedIcon => const Color(0xFF8B4513);
  @override Color get navUnselectedIcon => const Color(0xFFB0A98F);

  @override Color get badgeBg => const Color(0xFFA52A2A);
  @override Color get badgeBgSeen => const Color(0xFF4A7C44);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFA52A2A);
  @override Color get ratingStar => const Color(0xFFB8860B);
  @override Color get onWatchlist => const Color(0xFF4A7C44);

  @override Color get logicFlow => const Color(0xFF2E5A88);
  @override Color get dataValues => const Color(0xFF4A7C44);
  @override Color get constants => const Color(0xFFA52A2A);
  @override Color get functions => const Color(0xFF8B0000);
  @override Color get structural => const Color(0xFFB8860B);
  @override Color get comments => const Color(0xFF708090);

  @override Color get primaryText => const Color(0xFF2C2C2C);
  @override Color get secondaryText => const Color(0xFF5A5A5A);

  @override Color get placeholder => const Color(0xFFB0A98F);
}

class PinkyPalette extends AppPalette {
  @override Brightness get brightness => Brightness.light;
  
  @override Color get primaryBg => const Color(0xFFFFE4E1); // MistyRose
  @override Color get surface => const Color(0xFFFFF0F5); // LavenderBlush
  @override Color get selectionHighlight => const Color(0xFFFFC0CB); // Pink
  @override Color get statusAccent => const Color(0xFFFF69B4); // HotPink
  @override Color get visualSelection => const Color(0xFFDA70D6); // Orchid

  @override Color get navBg => const Color(0xFFFFB6C1); // LightPink
  @override Color get navSelectedIcon => const Color(0xFFC71585); // MediumVioletRed
  @override Color get navUnselectedIcon => const Color(0xFFDB7093); // PaleVioletRed

  @override Color get badgeBg => const Color(0xFF9370DB); // MediumPurple
  @override Color get badgeBgSeen => const Color(0xFF20B2AA); // LightSeaGreen
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFF7B68EE); // MediumSlateBlue
  @override Color get ratingStar => const Color(0xFF32CD32); // LimeGreen
  @override Color get onWatchlist => const Color(0xFFFF8C00); // DarkOrange

  @override Color get logicFlow => const Color(0xFFFF1493); // DeepPink
  @override Color get dataValues => const Color(0xFF00CED1); // DarkTurquoise
  @override Color get constants => const Color(0xFF8B008B); // DarkMagenta
  @override Color get functions => const Color(0xFF8A2BE2); // BlueViolet
  @override Color get structural => const Color(0xFF9400D3); // DarkViolet
  @override Color get comments => const Color(0xFFBC8F8F); // RosyBrown

  @override Color get primaryText => const Color(0xFF9400D3); // DarkViolet
  @override Color get secondaryText => const Color(0xFFBA55D3); // MediumOrchid

  @override Color get warning => const Color(0xFFFF00FF); // Magenta
  @override Color get success => const Color(0xFF00FF7F); // SpringGreen
  @override Color get info => const Color(0xFF00BFFF); // DeepSkyBlue
  @override Color get placeholder => const Color(0xFFFFB6C1);
}

class MidnightPalette extends AppPalette {
  @override Brightness get brightness => Brightness.dark;
  @override Color get primaryBg => const Color(0xFF1A1A2E);
  @override Color get surface => const Color(0xFF162447);
  @override Color get selectionHighlight => const Color(0xFF1F4068);
  @override Color get statusAccent => const Color(0xFFE94560);
  @override Color get visualSelection => const Color(0xFFE94560);

  @override Color get navBg => const Color(0xFF162447);
  @override Color get navSelectedIcon => const Color(0xFFE94560);
  @override Color get navUnselectedIcon => const Color(0xFF8B939A);

  @override Color get badgeBg => const Color(0xFFE94560);
  @override Color get badgeBgSeen => const Color(0xFF1F4068);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFE94560);
  @override Color get ratingStar => Colors.amber;
  @override Color get onWatchlist => Colors.green;

  @override Color get logicFlow => const Color(0xFF4ECCA3);
  @override Color get dataValues => const Color(0xFFB4E1FF);
  @override Color get constants => const Color(0xFFE94560);
  @override Color get functions => const Color(0xFFF0A500);
  @override Color get structural => const Color(0xFFE94560);
  @override Color get comments => const Color(0xFF8B939A);

  @override Color get primaryText => Colors.white;
  @override Color get secondaryText => Colors.white70;
}

class MintPalette extends AppPalette {
  @override Brightness get brightness => Brightness.light;
  @override Color get primaryBg => const Color(0xFFF0F5F5);
  @override Color get surface => Colors.white;
  @override Color get selectionHighlight => const Color(0xFFD9E9E9);
  @override Color get statusAccent => const Color(0xFF22A39F);
  @override Color get visualSelection => const Color(0xFF22A39F);

  @override Color get navBg => Colors.white;
  @override Color get navSelectedIcon => const Color(0xFF22A39F);
  @override Color get navUnselectedIcon => Colors.grey;

  @override Color get badgeBg => const Color(0xFFF94C66);
  @override Color get badgeBgSeen => const Color(0xFF22A39F);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFF94C66);
  @override Color get ratingStar => Colors.amber;
  @override Color get onWatchlist => Colors.green;

  @override Color get logicFlow => const Color(0xFF1E56A0);
  @override Color get dataValues => const Color(0xFF1A759F);
  @override Color get constants => const Color(0xFFD13438);
  @override Color get functions => const Color(0xFFCA5010);
  @override Color get structural => const Color(0xFF986F0B);
  @override Color get comments => Colors.grey.shade600;

  @override Color get primaryText => Colors.black;
  @override Color get secondaryText => Colors.black54;
}

class EspressoPalette extends AppPalette {
  @override Brightness get brightness => Brightness.dark;
  @override Color get primaryBg => const Color(0xFF2C2B2A);
  @override Color get surface => const Color(0xFF3B3A39);
  @override Color get selectionHighlight => const Color(0xFF4C4A48);
  @override Color get statusAccent => const Color(0xFFD4A276);
  @override Color get visualSelection => const Color(0xFFD4A276);

  @override Color get navBg => const Color(0xFF3B3A39);
  @override Color get navSelectedIcon => const Color(0xFFD4A276);
  @override Color get navUnselectedIcon => const Color(0xFF8B8589);

  @override Color get badgeBg => const Color(0xFFB56576);
  @override Color get badgeBgSeen => const Color(0xFF6D9F71);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFB56576);
  @override Color get ratingStar => Colors.amber;
  @override Color get onWatchlist => Colors.green;

  @override Color get logicFlow => const Color(0xFF81A1C1);
  @override Color get dataValues => const Color(0xFFB48EAD);
  @override Color get constants => const Color(0xFFB56576);
  @override Color get functions => const Color(0xFFD4A276);
  @override Color get structural => const Color(0xFFEBCB8B);
  @override Color get comments => const Color(0xFF8B8589);

  @override Color get primaryText => Colors.white;
  @override Color get secondaryText => Colors.white70;
}

class SolarizedLightPalette extends AppPalette {
  @override Brightness get brightness => Brightness.light;
  @override Color get primaryBg => const Color(0xFFFDF6E3);
  @override Color get surface => const Color(0xFFEEE8D5);
  @override Color get selectionHighlight => const Color(0xFFE8E2CF);
  @override Color get statusAccent => const Color(0xFF268BD2);
  @override Color get visualSelection => const Color(0xFF268BD2);

  @override Color get navBg => const Color(0xFFEEE8D5);
  @override Color get navSelectedIcon => const Color(0xFF268BD2);
  @override Color get navUnselectedIcon => const Color(0xFF93A1A1);

  @override Color get badgeBg => const Color(0xFFDC322F);
  @override Color get badgeBgSeen => const Color(0xFF859900);
  @override Color get badgeText => Colors.white;

  @override Color get likeHeart => const Color(0xFFDC322F);
  @override Color get ratingStar => const Color(0xFFB58900);
  @override Color get onWatchlist => const Color(0xFF859900);

  @override Color get logicFlow => const Color(0xFF268BD2);
  @override Color get dataValues => const Color(0xFF2AA198);
  @override Color get constants => const Color(0xFFDC322F);
  @override Color get functions => const Color(0xFFCB4B16);
  @override Color get structural => const Color(0xFFB58900);
  @override Color get comments => const Color(0xFF93A1A1);

  @override Color get primaryText => const Color(0xFF586E75);
  @override Color get secondaryText => const Color(0xFF657B83);
}
