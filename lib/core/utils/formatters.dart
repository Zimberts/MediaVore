import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static String formatSeenDate(DateTime date, [String? locale]) {
    try {
      return DateFormat.yMMMd(locale).format(date.toLocal());
    } catch (_) {
      return DateFormat.yMMMd().format(date.toLocal());
    }
  }

  static String formatSeenDateTime(DateTime date, [String? locale]) {
    try {
      return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
    } catch (_) {
      return DateFormat.yMMMd().add_Hm().format(date.toLocal());
    }
  }

  /// Returns the date input pattern for manual date entry based on [locale].
  /// English locales use 'MM/dd/yyyy', while French and other locales default to 'dd/MM/yyyy'.
  static String inputDatePattern(String? locale) {
    if (locale != null && locale.toLowerCase().startsWith('en')) {
      return 'MM/dd/yyyy';
    }
    return 'dd/MM/yyyy';
  }

  /// Formats [date] for manual text field entry according to [locale].
  static String formatInputDate(DateTime date, [String? locale]) {
    final pattern = inputDatePattern(locale);
    return DateFormat(pattern).format(date);
  }

  /// Parses [text] entered by user according to [locale], with fallback to alternate patterns.
  static DateTime? parseInputDate(String text, [String? locale]) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final primaryPattern = inputDatePattern(locale);
    try {
      return DateFormat(primaryPattern).parseStrict(trimmed);
    } catch (_) {}

    // Fallbacks
    final alternatePattern = primaryPattern == 'MM/dd/yyyy'
        ? 'dd/MM/yyyy'
        : 'MM/dd/yyyy';
    try {
      return DateFormat(alternatePattern).parseStrict(trimmed);
    } catch (_) {}

    try {
      return DateFormat('yyyy-MM-dd').parseStrict(trimmed);
    } catch (_) {}

    return null;
  }

  static String formatRuntime(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  /// Formats the duration of an episode (e.g. `45 min`, `1 h`, `1 h 15 min`).
  static String formatEpisodeDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }

  /// Formats the cumulative duration of a TV season.
  ///
  /// Examples:
  /// - 500 min (fr) -> '8,3 h'
  /// - 500 min (en) -> '8.3 h'
  /// - 500 min approximate (fr) -> '~8,3 h'
  /// - 45 min -> '45 min'
  /// - 60 min -> '1 h'
  /// - 120 min -> '2 h'
  static String formatSeasonDuration(
    int totalMinutes, {
    bool isApproximate = false,
    String? locale,
  }) {
    if (totalMinutes <= 0) return '';
    final prefix = isApproximate ? '~' : '';
    if (totalMinutes < 60) {
      return '$prefix$totalMinutes min';
    }
    final hours = totalMinutes / 60.0;
    final isFr = (locale ?? '').toLowerCase().startsWith('fr');
    final formatted = hours.toStringAsFixed(1);
    final trimmed = formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
    final localized = isFr ? trimmed.replaceAll('.', ',') : trimmed;
    return '$prefix$localized h';
  }

  /// Cumulative watch time with a unit that stays readable at any scale:
  /// `16h 40m`, `166h`, `41 days`, `1 year`, `1.5 years`.
  static String formatWatchTime(int minutes) {
    const day = 24 * 60;
    const year = 365 * day;
    if (minutes < day) return minutes == 0 ? '0m' : formatRuntime(minutes);
    if (minutes < 10 * day) return '${minutes ~/ 60}h';
    if (minutes < year) return '${minutes ~/ day} days';
    final years = minutes / year;
    if (years == years.truncateToDouble()) {
      final y = years.toInt();
      return y == 1 ? '1 year' : '$y years';
    }
    return '${years.toStringAsFixed(1)} years';
  }
}

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String oldText = oldValue.text;
    final String newText = newValue.text;

    // 1. If user is trying to delete a slash directly, we stop them and delete the digit before it instead.
    if (newText.length < oldText.length) {
      final int selectionEnd = oldValue.selection.end;
      if (selectionEnd > 0 && selectionEnd <= oldText.length) {
        final String characterToDelete = oldText[selectionEnd - 1];
        if (characterToDelete == '/') {
          // User hit backspace on a slash.
          // We want to delete the digit BEFORE the slash.
          String digits = oldText.replaceAll('/', '');
          int digitsBeforeCaret = oldText
              .substring(0, selectionEnd - 1)
              .replaceAll('/', '')
              .length;

          if (digitsBeforeCaret > 0) {
            String updatedDigits =
                digits.substring(0, digitsBeforeCaret - 1) +
                digits.substring(digitsBeforeCaret);
            return _rebuildValue(updatedDigits, digitsBeforeCaret - 1);
          } else {
            // Nothing left to delete
            return oldValue;
          }
        }
      }
    }

    // 2. Normal case: Extract digits and rebuild
    String digits = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    int caretPositionInDigits = _calculateDigitsBefore(
      newText,
      newValue.selection.end,
    );

    return _rebuildValue(digits, caretPositionInDigits);
  }

  int _calculateDigitsBefore(String text, int caret) {
    if (caret <= 0) return 0;
    if (caret > text.length) caret = text.length;
    return text.substring(0, caret).replaceAll(RegExp(r'[^0-9]'), '').length;
  }

  TextEditingValue _rebuildValue(String digits, int digitsBefore) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final String formatted = buffer.toString();

    // Calculate new caret position based on digitsBefore
    int newCaret = digitsBefore;
    if (digitsBefore > 2) newCaret++; // Add 1 for the first slash
    if (digitsBefore > 4) newCaret++; // Add 1 for the second slash

    // If the caret lands ON a slash (meaning we just typed a digit that pushed it there),
    // we jump the caret to the position AFTER the slash.
    if ((newCaret == 2 || newCaret == 5) && formatted.length > newCaret) {
      newCaret++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCaret.clamp(0, formatted.length),
      ),
    );
  }
}
