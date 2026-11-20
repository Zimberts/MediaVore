import 'package:flutter/foundation.dart';
import 'package:mediavore/core/constants/storage_keys.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Someone taking part in a "Together" session, with the list they shared.
@immutable
class TogetherParticipant {
  const TogetherParticipant({
    required this.name,
    this.entries = const [],
    this.totalParts = 1,
    this.scannedParts = const {1},
  });

  final String name;

  /// Shared titles.
  final List<SharedMediaEntry> entries;

  /// Multi-part QR code progress.
  final int totalParts;
  final Set<int> scannedParts;

  bool get isComplete => scannedParts.length >= totalParts;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.length >= 2
        ? trimmed.substring(0, 2).toUpperCase()
        : trimmed[0].toUpperCase();
  }
}

/// State of the "Together" session: participants, votes and whether a vote
/// is running.
///
/// Provided at app level, not held by the screen, so that it survives a
/// change of tab. Nothing is persisted: the session lives in memory until
/// [reset]. The shell hides the tab bar while [isVoting].
class TogetherSessionProvider extends ChangeNotifier {
  final List<TogetherParticipant> _participants = [];
  final Map<String, Set<String>> _votes = {};
  bool _isVoting = false;
  MediaType? _selectedType;
  String _selectedListName = 'watchlist';
  bool _hideSeen = false;

  List<TogetherParticipant> get participants =>
      List.unmodifiable(_participants);

  /// Titles each participant voted for, by participant name.
  Map<String, Set<String>> get votes => {
    for (final entry in _votes.entries)
      entry.key: Set.unmodifiable(entry.value),
  };

  bool get isVoting => _isVoting;

  bool get hasSession => _participants.isNotEmpty;

  MediaType? get selectedType => _selectedType;

  String get selectedListName => _selectedListName;

  bool get hideSeen => _hideSeen;

  void setSelectedType(MediaType? type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
  }

  void setSelectedListName(String listName) {
    if (_selectedListName == listName) return;
    _selectedListName = listName;
    notifyListeners();
  }

  void setHideSeen(bool hide) {
    if (_hideSeen == hide) return;
    _hideSeen = hide;
    notifyListeners();
  }

  void addParticipant(TogetherParticipant participant) {
    _participants.removeWhere((p) => p.name == participant.name);
    _participants.add(participant);
    notifyListeners();
  }

  void addParticipantChunk({
    required String name,
    required int part,
    required int totalParts,
    required List<SharedMediaEntry> entries,
  }) {
    final existingIndex = _participants.indexWhere((p) => p.name == name);
    if (existingIndex >= 0) {
      final existing = _participants[existingIndex];
      final combinedEntries = {...existing.entries, ...entries}.toList();
      final updatedParts = {...existing.scannedParts, part};
      _participants[existingIndex] = TogetherParticipant(
        name: name,
        entries: combinedEntries,
        totalParts: totalParts,
        scannedParts: updatedParts,
      );
    } else {
      _participants.add(
        TogetherParticipant(
          name: name,
          entries: entries,
          totalParts: totalParts,
          scannedParts: {part},
        ),
      );
    }
    notifyListeners();
  }

  void removeParticipant(String name) {
    final before = _participants.length;
    _participants.removeWhere((p) => p.name == name);
    final hadVotes = _votes.remove(name) != null;
    if (before != _participants.length || hadVotes) notifyListeners();
  }

  void startVote() {
    if (_isVoting) return;
    _isVoting = true;
    notifyListeners();
  }

  void castVote(String participant, String mediaKey, {bool approve = true}) {
    final votes = _votes.putIfAbsent(participant, () => <String>{});
    final changed = approve ? votes.add(mediaKey) : votes.remove(mediaKey);
    if (changed) notifyListeners();
  }

  /// Leaves the vote. Participants stay in the session; votes are dropped
  /// unless [keepVotes].
  void endVote({bool keepVotes = false}) {
    if (!_isVoting && (keepVotes || _votes.isEmpty)) return;
    _isVoting = false;
    if (!keepVotes) _votes.clear();
    notifyListeners();
  }

  /// Ends the session: participants and votes are forgotten.
  void reset() {
    _participants.clear();
    _votes.clear();
    _isVoting = false;
    _selectedType = null;
    _selectedListName = 'watchlist';
    _hideSeen = false;
    notifyListeners();
  }

  static const String togetherChoicesKey = StorageKeys.togetherChoicesKey;

  /// Increments the local counter of choices made together.
  Future<int> incrementTogetherChoicesCount({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final count = (p.getInt(togetherChoicesKey) ?? 0) + 1;
    await p.setInt(togetherChoicesKey, count);
    return count;
  }

  /// Retrieves the current local count of choices made together.
  Future<int> getTogetherChoicesCount({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return p.getInt(togetherChoicesKey) ?? 0;
  }
}
