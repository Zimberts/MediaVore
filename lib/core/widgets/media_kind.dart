import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// Kind of media a shared component is drawn for: it picks the icon, the
/// accent color and the name read by screen readers.
enum MediaKind {
  film,
  serie,
  livre;

  /// Kind of a TMDB [MediaType]; anything that is not a series is a film.
  static MediaKind fromMediaType(MediaType type) =>
      type == MediaType.tv ? MediaKind.serie : MediaKind.film;

  IconData get icon => switch (this) {
    MediaKind.film => Icons.movie,
    MediaKind.serie => Icons.tv,
    MediaKind.livre => Icons.menu_book,
  };

  /// Accent color of this kind.
  Color color(AppThemeExtension colors) => switch (this) {
    MediaKind.film => colors.film,
    MediaKind.serie => colors.serie,
    MediaKind.livre => colors.livre,
  };

  /// Tinted background that goes with [color].
  Color background(AppThemeExtension colors) => switch (this) {
    MediaKind.film => colors.filmBg,
    MediaKind.serie => colors.serieBg,
    MediaKind.livre => colors.livreBg,
  };

  /// Localized name ("Film", "Série", "Livre").
  String label(AppLocalizations l10n) => switch (this) {
    MediaKind.film => l10n.mediaKindFilm,
    MediaKind.serie => l10n.mediaKindSerie,
    MediaKind.livre => l10n.mediaKindLivre,
  };
}
