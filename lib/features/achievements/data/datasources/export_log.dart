import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dates of the exports (backups) of the user data, for the `backup_export`
/// achievements.
///
/// Exports leave no trace in the database, so they are logged separately.
/// The log is not part of the export archive and survives clearing the
/// achievements.
abstract class ExportLog {
  /// One date per calendar day with an export (its first export), oldest
  /// first.
  Future<List<DateTime>> dates();

  /// Logs an export done at [at]; a second export on the same calendar day is
  /// ignored.
  Future<void> record(DateTime at);
}

@LazySingleton(as: ExportLog)
class PrefsExportLog implements ExportLog {
  static const key = 'achievements_export_dates';

  final SharedPreferences _prefs;

  PrefsExportLog(this._prefs);

  @override
  Future<List<DateTime>> dates() async => [
    for (final s in _prefs.getStringList(key) ?? const <String>[])
      ?DateTime.tryParse(s),
  ]..sort();

  @override
  Future<void> record(DateTime at) async {
    final logged = await dates();
    if (logged.any(
      (d) => d.year == at.year && d.month == at.month && d.day == at.day,
    )) {
      return;
    }
    await _prefs.setStringList(key, [
      for (final d in logged) d.toIso8601String(),
      at.toIso8601String(),
    ]);
  }
}
