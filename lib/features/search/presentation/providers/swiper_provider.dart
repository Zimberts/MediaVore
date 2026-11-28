import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/utils/saga_sort.dart';
import 'package:mediavore/features/library/presentation/providers/library_provider.dart';
import 'package:mediavore/features/media_details/data/models/swipe_decision_model.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Represents a candidate presented on the Swiper screen.
/// Can be a standalone movie or an entire saga/collection.
class SwipeCardCandidate {
  final MediaItem item;
  final int? collectionId;
  final String? collectionName;
  final List<MediaItem> sagaItems;

  const SwipeCardCandidate({
    required this.item,
    this.collectionId,
    this.collectionName,
    this.sagaItems = const [],
  });

  bool get isSaga => collectionId != null && sagaItems.isNotEmpty;
}

/// Result of an undo operation.
class UndoResult {
  final SwipeCardCandidate restoredCandidate;
  final String decision;
  final String? targetList;

  const UndoResult({
    required this.restoredCandidate,
    required this.decision,
    this.targetList,
  });
}

class SwiperProvider extends ChangeNotifier {
  final MediaRepository repository;
  LibraryProvider? libraryProvider;

  SwiperProvider(this.repository, {this.libraryProvider});

  final List<SwipeCardCandidate> _candidates = [];
  final List<SwipeCardCandidate> _historyStack = [];

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  /// Last discover page the deck draws from.
  static const int _maxPages = 50;

  /// Items of the fetched discover pages not examined yet: a page can hold
  /// more titles than the deck needs, the rest is kept for the next load.
  final Queue<MediaItem> _pendingItems = Queue();

  int _sessionAddedCount = 0;
  int _sessionDiscardedCount = 0;

  final Set<int> _decidedTmdbIds = {};
  final Set<int> _seenSagaCollectionIds = {};

  // External filters passed during refresh/load
  Set<int> _existingListIds = {};
  Set<int> _seenIds = {};

  SearchFilters _filters = const SearchFilters();
  int _loadGeneration = 0;

  List<SwipeCardCandidate> get candidates => List.unmodifiable(_candidates);
  SwipeCardCandidate? get currentCandidate =>
      _candidates.isNotEmpty ? _candidates.first : null;

  SearchFilters get filters => _filters;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore || _pendingItems.isNotEmpty;
  bool get canUndo => _historyStack.isNotEmpty;

  int get sessionAddedCount => _sessionAddedCount;
  int get sessionDiscardedCount => _sessionDiscardedCount;

  /// Initializes the swiper and preloads the first candidate cards.
  Future<void> init({
    Set<int> existingListIds = const {},
    Set<int> seenIds = const {},
    SearchFilters? filters,
  }) async {
    _existingListIds = Set.from(existingListIds);
    _seenIds = Set.from(seenIds);
    if (filters != null) {
      _filters = filters;
    }

    _loadGeneration++;
    final generation = _loadGeneration;
    _isFetchingMore = false;
    _isLoading = true;
    notifyListeners();

    try {
      final decided = await repository.getDecidedTmdbIds();
      if (generation != _loadGeneration) return;
      _decidedTmdbIds.clear();
      _decidedTmdbIds.addAll(decided);

      final pastDecisions = await repository.getSwipeDecisions();
      if (generation != _loadGeneration) return;
      _seenSagaCollectionIds.clear();
      for (final d in pastDecisions) {
        if (d.collectionId != null) {
          _seenSagaCollectionIds.add(d.collectionId!);
        }
      }

      _candidates.clear();
      _historyStack.clear();
      _sessionAddedCount = 0;
      _sessionDiscardedCount = 0;
      _currentPage = 1;
      _hasMore = true;
      _pendingItems.clear();

      await _loadCandidatesUntilThreshold();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Applies new discovery [newFilters] and reloads the deck from page 1,
  /// preserving session decisions and undo history.
  Future<void> setFilters(SearchFilters newFilters) async {
    if (_filters == newFilters) return;
    _filters = newFilters;
    _loadGeneration++;
    final generation = _loadGeneration;

    _candidates.clear();
    _pendingItems.clear();
    _currentPage = 1;
    _hasMore = true;
    _isFetchingMore = false;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadCandidatesUntilThreshold();
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Updates the external filters (e.g. if the user marks something seen elsewhere).
  void updateFilters({Set<int>? existingListIds, Set<int>? seenIds}) {
    if (existingListIds != null) _existingListIds = Set.from(existingListIds);
    if (seenIds != null) _seenIds = Set.from(seenIds);

    // Prune any candidates that now match the updated filters
    _candidates.removeWhere(
      (c) =>
          _decidedTmdbIds.contains(c.item.id) ||
          _existingListIds.contains(c.item.id) ||
          _seenIds.contains(c.item.id),
    );
    notifyListeners();
  }

  /// Swipes right (Accept / Add to list).
  Future<void> swipeRight(String targetList) async {
    if (_candidates.isEmpty) return;

    final candidate = _candidates.removeAt(0);
    _historyStack.add(candidate);
    final now = DateTime.now();

    if (candidate.isSaga) {
      final decisions = <SwipeDecisionModel>[];
      final toAdd = <MediaItem>[];
      for (final movie in candidate.sagaItems) {
        // Add all movies from the saga not already in list
        if (!_existingListIds.contains(movie.id)) {
          toAdd.add(movie);
          _existingListIds.add(movie.id);
        }
        decisions.add(
          SwipeDecisionModel(
            tmdbId: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            decision: 'added',
            decidedAt: now,
            targetList: targetList,
            collectionId: candidate.collectionId,
            collectionName: candidate.collectionName,
          ),
        );
        _decidedTmdbIds.add(movie.id);
      }
      if (toAdd.isNotEmpty) {
        if (libraryProvider != null) {
          await libraryProvider!.addAllToList(toAdd, targetList);
        } else {
          for (final movie in toAdd) {
            await repository.addToList(movie, targetList);
          }
        }
      }
      if (candidate.collectionId != null) {
        _seenSagaCollectionIds.add(candidate.collectionId!);
      }
      await repository.recordSwipeDecisions(decisions);
    } else {
      if (libraryProvider != null) {
        await libraryProvider!.addToList(candidate.item, targetList);
      } else {
        await repository.addToList(candidate.item, targetList);
      }
      _existingListIds.add(candidate.item.id);
      _decidedTmdbIds.add(candidate.item.id);

      final decision = SwipeDecisionModel(
        tmdbId: candidate.item.id,
        title: candidate.item.title,
        posterPath: candidate.item.posterPath,
        decision: 'added',
        decidedAt: now,
        targetList: targetList,
      );
      await repository.recordSwipeDecision(decision);
    }

    _sessionAddedCount++;
    notifyListeners();

    _checkPrefetch();
  }

  /// Swipes left (Pass / Discard).
  Future<void> swipeLeft() async {
    if (_candidates.isEmpty) return;

    final candidate = _candidates.removeAt(0);
    _historyStack.add(candidate);
    final now = DateTime.now();

    if (candidate.isSaga) {
      final decisions = <SwipeDecisionModel>[];
      for (final movie in candidate.sagaItems) {
        decisions.add(
          SwipeDecisionModel(
            tmdbId: movie.id,
            title: movie.title,
            posterPath: movie.posterPath,
            decision: 'discarded',
            decidedAt: now,
            collectionId: candidate.collectionId,
            collectionName: candidate.collectionName,
          ),
        );
        _decidedTmdbIds.add(movie.id);
      }
      if (candidate.collectionId != null) {
        _seenSagaCollectionIds.add(candidate.collectionId!);
      }
      await repository.recordSwipeDecisions(decisions);
    } else {
      _decidedTmdbIds.add(candidate.item.id);
      final decision = SwipeDecisionModel(
        tmdbId: candidate.item.id,
        title: candidate.item.title,
        posterPath: candidate.item.posterPath,
        decision: 'discarded',
        decidedAt: now,
      );
      await repository.recordSwipeDecision(decision);
    }

    _sessionDiscardedCount++;
    notifyListeners();

    _checkPrefetch();
  }

  /// Undoes the last swipe decision.
  Future<UndoResult?> undoLastDecision() async {
    if (_historyStack.isEmpty) return null;

    final lastCandidate = _historyStack.removeLast();
    final undone = await repository.undoLastSwipeDecision();

    if (undone != null) {
      if (undone.decision == 'added') {
        _sessionAddedCount = max(0, _sessionAddedCount - 1);
        if (undone.targetList != null) {
          if (lastCandidate.isSaga) {
            for (final movie in lastCandidate.sagaItems) {
              if (libraryProvider != null) {
                await libraryProvider!.removeFromList(
                  movie,
                  undone.targetList!,
                );
              } else {
                await repository.removeFromList(
                  movie.id,
                  MediaType.movie,
                  undone.targetList!,
                );
              }
              _existingListIds.remove(movie.id);
              _decidedTmdbIds.remove(movie.id);
            }
          } else {
            if (libraryProvider != null) {
              await libraryProvider!.removeFromList(
                lastCandidate.item,
                undone.targetList!,
              );
            } else {
              await repository.removeFromList(
                undone.tmdbId,
                MediaType.movie,
                undone.targetList!,
              );
            }
            _existingListIds.remove(undone.tmdbId);
            _decidedTmdbIds.remove(undone.tmdbId);
          }
        }
      } else {
        _sessionDiscardedCount = max(0, _sessionDiscardedCount - 1);
        if (lastCandidate.isSaga) {
          for (final movie in lastCandidate.sagaItems) {
            _decidedTmdbIds.remove(movie.id);
          }
        } else {
          _decidedTmdbIds.remove(undone.tmdbId);
        }
      }

      // The saga stays in _seenSagaCollectionIds: its card is back in the
      // deck, so a later load must not propose it a second time.
      _candidates.insert(0, lastCandidate);
      notifyListeners();

      return UndoResult(
        restoredCandidate: lastCandidate,
        decision: undone.decision,
        targetList: undone.targetList,
      );
    }

    return null;
  }

  void _checkPrefetch() {
    if (_candidates.length < 3 && !_isFetchingMore && hasMore) {
      unawaited(_loadCandidatesUntilThreshold());
    }
  }

  Future<void> _loadCandidatesUntilThreshold({int targetCount = 4}) async {
    if (_isFetchingMore || !hasMore) return;
    _isFetchingMore = true;
    final generation = _loadGeneration;
    final activeFilters = _filters;

    try {
      while (_candidates.length < targetCount) {
        if (generation != _loadGeneration) return;
        if (_pendingItems.isEmpty) {
          if (!_hasMore) break;
          if (_currentPage > _maxPages) {
            _hasMore = false;
            break;
          }
          final pageItems = activeFilters.isEmpty
              ? await repository.discoverMedia(page: _currentPage)
              : await repository.discoverMedia(
                  page: _currentPage,
                  filters: activeFilters,
                  genresMatchAny: true,
                );
          if (generation != _loadGeneration) return;
          _currentPage++;

          if (pageItems.isEmpty) {
            _hasMore = false;
            break;
          }
          _pendingItems.addAll(pageItems);
        }

        final item = _pendingItems.removeFirst();
        if (_decidedTmdbIds.contains(item.id)) continue;
        if (_existingListIds.contains(item.id)) continue;
        if (_seenIds.contains(item.id)) continue;
        if (_candidates.any((c) => c.item.id == item.id)) continue;

        // Enrich with details to detect collections/sagas
        try {
          final details = await repository.getMediaDetails(item.id);
          if (generation != _loadGeneration) return;
          final collId = details.item.collectionId;
          final collName = details.item.collectionName;

          if (collId != null &&
              details.collection != null &&
              details.collection!.isNotEmpty) {
            if (_seenSagaCollectionIds.contains(collId)) continue;

            final sagaSorted = sortSagaByDate(details.collection!);
            _seenSagaCollectionIds.add(collId);

            _candidates.add(
              SwipeCardCandidate(
                item: details.item,
                collectionId: collId,
                collectionName: collName ?? details.item.title,
                sagaItems: sagaSorted,
              ),
            );
          } else {
            _candidates.add(SwipeCardCandidate(item: details.item));
          }
        } catch (_) {
          if (generation != _loadGeneration) return;
          _candidates.add(SwipeCardCandidate(item: item));
        }
      }
    } catch (_) {
      // In case of network errors, preserve existing candidates
    } finally {
      if (generation == _loadGeneration) {
        _isFetchingMore = false;
        notifyListeners();
      }
    }
  }
}
