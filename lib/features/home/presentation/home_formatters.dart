import 'package:intl/intl.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/media_kind.dart';

/// Short, relative date of a last activity: "today", "yesterday", "5 d ago",
/// "3 wk ago", "2 mo ago".
String formatLastActivity(AppLocalizations l10n, DateTime date, DateTime now) {
  final days = now.difference(date).inDays;
  if (days <= 0) return l10n.homeAgoToday;
  if (days == 1) return l10n.homeAgoYesterday;
  if (days < 14) return l10n.homeAgoDays(days);
  if (days < 60) return l10n.homeAgoWeeks((days / 7).round());
  return l10n.homeAgoMonths((days / 30).round());
}

/// Kinds offered as filter chips of "Also in progress", in display order.
///
/// Empty unless at least two kinds are present: a filter with a single
/// useful value is not shown.
List<MediaKind> progressFilterKinds(Iterable<MediaKind> kinds) {
  final present = kinds.toSet();
  if (present.length < 2) return const [];
  return [
    for (final kind in MediaKind.values)
      if (present.contains(kind)) kind,
  ];
}

/// Rotating window of at most [count] picks over [candidates], starting at
/// [offset]; "Another idea" moves the offset by [count].
List<T> rotatingPicks<T>(List<T> candidates, int offset, {int count = 3}) {
  if (candidates.isEmpty) return const [];
  return [
    for (var i = 0; i < count && i < candidates.length; i++)
      candidates[(offset + i) % candidates.length],
  ];
}

/// Date of the Home header: "Saturday, November 14" / "Samedi 14 novembre".
String formatHomeDate(AppLocalizations l10n, DateTime date) {
  String format(String locale) => DateFormat.MMMMEEEEd(locale).format(date);
  String text;
  try {
    text = format(l10n.localeName);
  } on Exception {
    // Date symbols are loaded by the localization delegates of the app;
    // without them only the built-in locale is available.
    text = format('en_US');
  }
  return toBeginningOfSentenceCase(text);
}

/// Medium date, "Nov 14, 2026" / "14 nov. 2026".
String formatMediumDate(AppLocalizations l10n, DateTime date) {
  try {
    return DateFormat.yMMMd(l10n.localeName).format(date);
  } on Exception {
    // See [formatHomeDate].
    return DateFormat.yMMMd('en_US').format(date);
  }
}

/// Short month of a date badge, "Nov" / "nov.".
String formatShortMonth(AppLocalizations l10n, DateTime date) {
  try {
    return DateFormat.MMM(l10n.localeName).format(date);
  } on Exception {
    return DateFormat.MMM('en_US').format(date);
  }
}

/// Month title, "November 2026" / "Novembre 2026".
String formatMonthYear(AppLocalizations l10n, DateTime month) {
  String text;
  try {
    text = DateFormat.yMMMM(l10n.localeName).format(month);
  } on Exception {
    text = DateFormat.yMMMM('en_US').format(month);
  }
  return toBeginningOfSentenceCase(text);
}
