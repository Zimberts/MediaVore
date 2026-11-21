/// Typed access to decoded JSON (TMDB payloads, cached seasons).
///
/// `jsonDecode` yields `dynamic`; these helpers give the analyzer static
/// types without changing behaviour for well-formed payloads. Entries that
/// are not JSON objects are skipped instead of throwing at runtime.
library;

/// The JSON objects of [value] when it is a list, or an empty list.
List<Map<String, dynamic>> jsonObjectList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is Map<String, dynamic>)
        entry
      else if (entry is Map)
        entry.cast<String, dynamic>(),
  ];
}

/// [value] as a JSON object, or `null` when it is not one.
Map<String, dynamic>? jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}
