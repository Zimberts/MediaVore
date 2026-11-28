import 'package:flutter/foundation.dart';

/// Semantic version (`MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`) with SemVer 2.0.0
/// precedence comparison.
@immutable
class SemVer implements Comparable<SemVer> {
  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease = const [],
  });

  final int major;
  final int minor;
  final int patch;

  /// Dot-separated pre-release identifiers (empty for a stable release).
  final List<String> preRelease;

  static final RegExp _pattern = RegExp(
    r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z.-]+)?$',
  );

  /// Parses [input] into a [SemVer], or returns `null` if invalid.
  static SemVer? tryParse(String input) {
    final match = _pattern.firstMatch(input.trim());
    if (match == null) return null;
    final major = int.tryParse(match.group(1)!);
    final minor = int.tryParse(match.group(2)!);
    final patch = int.tryParse(match.group(3)!);
    if (major == null || minor == null || patch == null) return null;
    final pre = match.group(4);
    final preRelease = pre == null || pre.isEmpty
        ? const <String>[]
        : pre.split('.');
    return SemVer(
      major: major,
      minor: minor,
      patch: patch,
      preRelease: preRelease,
    );
  }

  /// Parses [input] into a [SemVer], throwing [FormatException] if invalid.
  factory SemVer.parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Invalid semantic version: "$input"');
    }
    return parsed;
  }

  bool get isPreRelease => preRelease.isNotEmpty;

  @override
  int compareTo(SemVer other) {
    final majorCmp = major.compareTo(other.major);
    if (majorCmp != 0) return majorCmp;
    final minorCmp = minor.compareTo(other.minor);
    if (minorCmp != 0) return minorCmp;
    final patchCmp = patch.compareTo(other.patch);
    if (patchCmp != 0) return patchCmp;

    // A normal version has higher precedence than a pre-release version.
    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final minLen = preRelease.length < other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var i = 0; i < minLen; i++) {
      final a = preRelease[i];
      final b = other.preRelease[i];
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) {
        final cmp = aNum.compareTo(bNum);
        if (cmp != 0) return cmp;
      } else if (aNum != null) {
        // Numeric identifiers always have lower precedence than non-numeric.
        return -1;
      } else if (bNum != null) {
        return 1;
      } else {
        final cmp = a.compareTo(b);
        if (cmp != 0) return cmp;
      }
    }
    return preRelease.length.compareTo(other.preRelease.length);
  }

  bool operator >(SemVer other) => compareTo(other) > 0;
  bool operator <(SemVer other) => compareTo(other) < 0;
  bool operator >=(SemVer other) => compareTo(other) >= 0;
  bool operator <=(SemVer other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemVer &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          listEquals(preRelease, other.preRelease);

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, Object.hashAll(preRelease));

  @override
  String toString() => preRelease.isEmpty
      ? '$major.$minor.$patch'
      : '$major.$minor.$patch-${preRelease.join('.')}';
}
