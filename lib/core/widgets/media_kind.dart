import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';

/// Kind of media a shared component is drawn for: it picks the icon, the
/// accent color and the name read by screen readers.
enum MediaKind {
  movie,
  series,
  book;

  /// Kind of a TMDB [MediaType]; anything that is not a series is a movie.
  static MediaKind fromMediaType(MediaType type) =>
      type == MediaType.tv ? MediaKind.series : MediaKind.movie;

  IconData get icon => switch (this) {
    MediaKind.movie => Icons.movie,
    MediaKind.series => Icons.tv,
    MediaKind.book => Icons.menu_book,
  };

  /// Accent color of this kind.
  Color color(AppThemeExtension colors) => switch (this) {
    MediaKind.movie => colors.movie,
    MediaKind.series => colors.series,
    MediaKind.book => colors.book,
  };

  /// Tinted background that goes with [color].
  Color background(AppThemeExtension colors) => switch (this) {
    MediaKind.movie => colors.movieBg,
    MediaKind.series => colors.seriesBg,
    MediaKind.book => colors.bookBg,
  };

  /// Localized name ("Movie", "Series", "Book").
  String label(AppLocalizations l10n) => switch (this) {
    MediaKind.movie => l10n.mediaKindMovie,
    MediaKind.series => l10n.mediaKindSeries,
    MediaKind.book => l10n.mediaKindBook,
  };
}
