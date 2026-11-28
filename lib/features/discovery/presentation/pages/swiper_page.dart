import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/features/discovery/presentation/widgets/swipe_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/seen_manager.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SwiperPage extends StatefulWidget {
  final SwiperProvider? customSwiperProvider;

  const SwiperPage({super.key, this.customSwiperProvider});

  @override
  State<SwiperPage> createState() => _SwiperPageState();
}

class _SwiperPageState extends State<SwiperPage> {
  late final SwiperProvider _swiper;
  late final bool _ownsSwiper;

  @override
  void initState() {
    super.initState();
    if (widget.customSwiperProvider != null) {
      _swiper = widget.customSwiperProvider!;
      _ownsSwiper = false;
      final search = context.read<SearchProvider?>();
      _swiper.libraryProvider ??=
          context.read<LibraryProvider?>() ?? search?.libraryProvider;
      _swiper.searchProvider ??= search;
    } else {
      _ownsSwiper = true;
      final search = context.read<SearchProvider>();
      final repo = locator.isRegistered<MediaRepository>()
          ? locator<MediaRepository>()
          : search.repository;
      final library =
          context.read<LibraryProvider?>() ?? search.libraryProvider;
      _swiper = SwiperProvider(
        repo,
        libraryProvider: library,
        searchProvider: search,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSwiper();
    });
  }

  @override
  void dispose() {
    if (_ownsSwiper) {
      _swiper.dispose();
    }
    super.dispose();
  }

  void _initSwiper() {
    final searchProvider = context.read<SearchProvider>();
    final existingListIds = searchProvider.listEntries.values
        .expand((list) => list)
        .map((entry) => int.tryParse(entry.split(':').first))
        .whereType<int>()
        .toSet();

    final seenIds = searchProvider.seenItems.map((s) => s.tmdbId).toSet();

    _swiper.init(existingListIds: existingListIds, seenIds: seenIds);
  }

  void _handleSwipeRight(
    SwipeCardCandidate candidate,
    String targetList,
  ) async {
    await _swiper.swipeRight(targetList);
  }

  void _handleSwipeLeft(SwipeCardCandidate candidate) async {
    await _swiper.swipeLeft();
  }

  Future<void> _handleSwipeSeen(
    SwipeCardCandidate candidate,
    bool advanced,
  ) async {
    if (advanced) {
      final result = await showSeenDateTimePickerDialog(
        context,
        item: candidate.item,
        initialDate: DateTime.now(),
      );
      if (!mounted || result == null) return;
      await _swiper.swipeSeen(seenDate: result.date);
    } else {
      await _swiper.swipeSeen();
    }
  }

  void _handleUndo() async {
    await _swiper.undoLastDecision();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SwiperProvider>.value(
      value: _swiper,
      child: Consumer2<SwiperProvider, SettingsProvider>(
        builder: (context, swiper, settings, _) {
          final theme = Theme.of(context);
          final primary = theme.colorScheme.primary;
          final error = theme.colorScheme.error;
          final searchProvider = context.watch<SearchProvider>();

          final myLists = searchProvider.listNames.isNotEmpty
              ? searchProvider.listNames
              : ['watchlist'];

          final targetList = myLists.contains(settings.swipeTargetList)
              ? settings.swipeTargetList
              : myLists.first;

          final candidate = swiper.currentCandidate;

          return Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.swiperTitle),
              actions: [
                if (swiper.sessionAddedCount > 0 ||
                    swiper.sessionSeenCount > 0 ||
                    swiper.sessionDiscardedCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.52,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              context.l10n.swiperSessionStats(
                                swiper.sessionAddedCount,
                                swiper.sessionSeenCount,
                                swiper.sessionDiscardedCount,
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Target list selector header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${context.l10n.swiperAddTo} : ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const Key('swiper_target_list_dropdown'),
                            value: targetList,
                            isExpanded: true,
                            items: myLists.map((name) {
                              final label = name == 'watchlist'
                                  ? context.l10n.listsWatchlist
                                  : name;
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null && newVal != targetList) {
                                settings.setSwipeTargetList(newVal);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Area
                Expanded(
                  child: swiper.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : candidate == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: EmptyState(
                              icon: Icons.movie_filter_outlined,
                              title: context.l10n.swiperEmptyTitle,
                              message: context.l10n.swiperEmptyMessage,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: SwipeCard(
                            key: ValueKey(
                              candidate.isSaga
                                  ? 'saga_${candidate.collectionId}'
                                  : 'movie_${candidate.item.id}',
                            ),
                            candidate: candidate,
                            onSwipeRight: () =>
                                _handleSwipeRight(candidate, targetList),
                            onSwipeLeft: () => _handleSwipeLeft(candidate),
                            onSwipeUp: () => _handleSwipeSeen(
                              candidate,
                              settings.advancedTracking,
                            ),
                          ),
                        ),
                ),

                // Action Buttons Bar
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Discard button (left)
                        IconButton.filledTonal(
                          key: const Key('swiper_discard_button'),
                          icon: const Icon(Icons.close),
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56),
                            backgroundColor: error.withValues(alpha: 0.15),
                            foregroundColor: error,
                          ),
                          tooltip: context.l10n.swiperDiscard,
                          onPressed: candidate != null
                              ? () => _handleSwipeLeft(candidate)
                              : null,
                        ),

                        // Undo button
                        IconButton.outlined(
                          key: const Key('swiper_undo_button'),
                          icon: const Icon(Icons.undo),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          tooltip: context.l10n.swiperUndo,
                          onPressed: swiper.canUndo ? _handleUndo : null,
                        ),

                        // Mark as seen button
                        IconButton.filledTonal(
                          key: const Key('swiper_seen_button'),
                          icon: const Icon(Icons.visibility_outlined),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: context.appColors.success
                                .withValues(alpha: 0.15),
                            foregroundColor: context.appColors.success,
                          ),
                          tooltip: settings.advancedTracking
                              ? context.l10n.commonMarkAsSeenWithDots
                              : context.l10n.commonMarkAsSeen,
                          onPressed: candidate != null
                              ? () => _handleSwipeSeen(
                                  candidate,
                                  settings.advancedTracking,
                                )
                              : null,
                        ),

                        // Add button (right)
                        IconButton.filled(
                          key: const Key('swiper_add_button'),
                          icon: const Icon(Icons.check),
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56),
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                          tooltip: context.l10n.swiperAdd,
                          onPressed: candidate != null
                              ? () => _handleSwipeRight(candidate, targetList)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
