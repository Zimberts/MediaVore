import 'package:flutter/services.dart';

class Formatters {
  static String formatRuntime(int? minutes) {
    if (minutes == null || minutes == 0) return '';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }
}

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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
          int digitsBeforeCaret = oldText.substring(0, selectionEnd - 1).replaceAll('/', '').length;
          
          if (digitsBeforeCaret > 0) {
            String updatedDigits = digits.substring(0, digitsBeforeCaret - 1) + digits.substring(digitsBeforeCaret);
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

    int caretPositionInDigits = _calculateDigitsBefore(newText, newValue.selection.end);

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
      selection: TextSelection.collapsed(offset: newCaret.clamp(0, formatted.length)),
    );
  }
}
