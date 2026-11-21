import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/features/discovery/presentation/widgets/swipe_card.dart';
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
      _swiper.libraryProvider ??= context.read<LibraryProvider?>() ??
          context.read<SearchProvider?>()?.libraryProvider;
    } else {
      _ownsSwiper = true;
      final repo = locator.isRegistered<MediaRepository>()
          ? locator<MediaRepository>()
          : context.read<SearchProvider>().repository;
      final library = context.read<LibraryProvider?>() ??
          context.read<SearchProvider>().libraryProvider;
      _swiper = SwiperProvider(repo, libraryProvider: library);
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
    if (!mounted) return;

    final l10n = context.l10n;
    final message = candidate.isSaga
        ? l10n.swiperSagaAddedMessage(
            candidate.collectionName ?? candidate.item.title,
            candidate.sagaItems.length,
          )
        : l10n.swiperAddedMessage(candidate.item.title, targetList);

    showAppMessage(
      message,
      actionLabel: l10n.swiperUndo,
      onAction: () => _handleUndo(),
    );
  }

  void _handleSwipeLeft(SwipeCardCandidate candidate) async {
    await _swiper.swipeLeft();
    if (!mounted) return;

    final l10n = context.l10n;
    final message = candidate.isSaga
        ? l10n.swiperSagaDiscardedMessage
        : l10n.swiperDiscardedMessage;

    showAppMessage(
      message,
      actionLabel: l10n.swiperUndo,
      onAction: () => _handleUndo(),
    );
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
                    swiper.sessionDiscardedCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
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
                      bottom: BorderSide(color: theme.dividerColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${context.l10n.swiperAddTo} : ',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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

                        // Undo button (center)
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
