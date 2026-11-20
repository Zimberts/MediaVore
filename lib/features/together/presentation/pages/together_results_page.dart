import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/bounded_concurrency.dart';
import 'package:mediavore/core/utils/list_intersection_calculator.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/empty_state.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/together/presentation/models/together_vote_engine.dart';
import 'package:mediavore/features/together/presentation/pages/together_vote_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:provider/provider.dart';

class TogetherResultsPage extends StatefulWidget {
  const TogetherResultsPage({super.key});

  @override
  State<TogetherResultsPage> createState() => _TogetherResultsPageState();
}

class _TogetherResultsPageState extends State<TogetherResultsPage> {
  final Map<String, MediaItem> _mediaCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItemsDetails();
    });
  }

  Future<void> _loadItemsDetails() async {
    final searchProvider = context.read<SearchProvider>();
    final session = context.read<TogetherSessionProvider>();

    final hostListEntries = ListShareCodec.parseEntries(
      searchProvider.listEntries[session.selectedListName] ?? const [],
    );

    final allEntries = <SharedMediaEntry>{
      ...hostListEntries,
      for (final p in session.participants) ...p.entries,
    };

    if (allEntries.isEmpty) return;

    final entriesToFetch = allEntries.where((entry) {
      final key = '${entry.id}:${entry.type.name}';
      return !_mediaCache.containsKey(key);
    }).toList();

    if (entriesToFetch.isEmpty) return;

    setState(() => _isLoading = true);

    await mapWithConcurrency(entriesToFetch, 4, (entry) async {
      final key = '${entry.id}:${entry.type.name}';
      try {
        final details = await searchProvider.getMediaDetails(
          entry.id,
          entry.type,
        );
        _mediaCache[key] = details.item;
      } catch (_) {
        _mediaCache[key] = MediaItem(
          id: entry.id,
          title: 'Unknown',
          overview: '',
          releaseDate: '',
          mediaType: entry.type,
        );
      }
    });

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onWatchThis(MediaItem item) {
    final session = context.read<TogetherSessionProvider>();
    session.reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MediaDetailPage(item: item)),
    );
  }

  void _pickRandom(List<SharedMediaEntry> candidates) {
    if (candidates.isEmpty) return;
    final random = math.Random();
    final pickedEntry = candidates[random.nextInt(candidates.length)];
    final key = '${pickedEntry.id}:${pickedEntry.type.name}';
    final item = _mediaCache[key] ??
        MediaItem(
          id: pickedEntry.id,
          title: 'Title',
          overview: '',
          releaseDate: '',
          mediaType: pickedEntry.type,
        );

    final l10n = context.l10n;
    final colors = context.appColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.togetherRandomPick),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.posterPath != null && item.posterPath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  TmdbImageUtils.buildUrl(
                    item.posterPath,
                    size: TmdbImageSize.w342,
                  )!,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (item.voteAverage != null && item.voteAverage! > 0) ...[
              const SizedBox(height: 6),
              Text(
                '★ ${item.voteAverage!.toStringAsFixed(1)}',
                style: TextStyle(
                  color: colors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickRandom(candidates);
            },
            child: Text(l10n.homeTonightOtherIdea),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onWatchThis(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.success,
              foregroundColor: contrastingForeground(colors.success),
            ),
            child: Text(l10n.togetherWatchThis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();
    final session = context.watch<TogetherSessionProvider>();

    final hostListEntries = ListShareCodec.parseEntries(
      searchProvider.listEntries[session.selectedListName] ?? const [],
    );

    final seenKeys = {
      for (final s in searchProvider.seenItems) (s.tmdbId, s.type),
    };

    final allLists = [
      (
        name: l10n.togetherYouHost,
        initials: 'MOI',
        entries: hostListEntries,
      ),
      for (final p in session.participants)
        (
          name: p.name,
          initials: p.initials,
          entries: p.entries,
        ),
    ];

    final result = ListIntersectionCalculator.multiIntersect(
      lists: allLists,
      typeFilter: session.selectedType,
      hideSeen: session.hideSeen,
      seenKeys: seenKeys,
    );

    // Sort common entries by rating descending
    final commonSorted = List<SharedMediaEntry>.from(result.commonEntries)
      ..sort((a, b) {
        final itemA = _mediaCache['${a.id}:${a.type.name}'];
        final itemB = _mediaCache['${b.id}:${b.type.name}'];
        final ratingA = itemA?.voteAverage ?? 0;
        final ratingB = itemB?.voteAverage ?? 0;
        return ratingB.compareTo(ratingA);
      });

    final almostSorted = List<SharedMediaEntry>.from(result.almostEntries)
      ..sort((a, b) {
        final itemA = _mediaCache['${a.id}:${a.type.name}'];
        final itemB = _mediaCache['${b.id}:${b.type.name}'];
        final ratingA = itemA?.voteAverage ?? 0;
        final ratingB = itemB?.voteAverage ?? 0;
        return ratingB.compareTo(ratingA);
      });

    final totalParticipants = allLists.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.togetherCommonCount(commonSorted.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.togetherResetSession,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.togetherResetSession),
                  content: Text(l10n.togetherResetConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        session.reset();
                        Navigator.pop(context);
                      },
                      child: Text(l10n.commonConfirm),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter row
                        Row(
                          children: [
                            FilterChip(
                              key: const Key('together_hide_seen_chip'),
                              selected: session.hideSeen,
                              label: Text(l10n.togetherHideSeen),
                              onSelected: session.setHideSeen,
                            ),
                          ],
                        ),

                        // If more than 6 common titles, announce limit for voting
                        if (commonSorted.length > 6) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.togetherVoteLimitNotice(
                                      commonSorted.length,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Common titles or Empty state
                if (commonSorted.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 32,
                      ),
                      child: EmptyState(
                        icon: Icons.search_off,
                        title: l10n.togetherEmptyCommonTitle,
                        message: l10n.togetherEmptyCommonMessage,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = commonSorted[index];
                          final key = '${entry.id}:${entry.type.name}';
                          final item = _mediaCache[key] ??
                              MediaItem(
                                id: entry.id,
                                title: '...',
                                overview: '',
                                releaseDate: '',
                                mediaType: entry.type,
                              );
                          final initials =
                              result.participantInitials[key] ?? const [];

                          return _buildMediaTile(
                            item: item,
                            initials: initials,
                            colors: colors,
                            theme: theme,
                          );
                        },
                        childCount: commonSorted.length,
                      ),
                    ),
                  ),

                // Almost section (N-1 out of N, for N >= 3)
                if (totalParticipants >= 3 && almostSorted.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: SectionHeader(
                        title: l10n.togetherAlmostSection(
                          totalParticipants - 1,
                          totalParticipants,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = almostSorted[index];
                          final key = '${entry.id}:${entry.type.name}';
                          final item = _mediaCache[key] ??
                              MediaItem(
                                id: entry.id,
                                title: '...',
                                overview: '',
                                releaseDate: '',
                                mediaType: entry.type,
                              );
                          final initials =
                              result.participantInitials[key] ?? const [];

                          return _buildMediaTile(
                            item: item,
                            initials: initials,
                            colors: colors,
                            theme: theme,
                          );
                        },
                        childCount: almostSorted.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('together_random_pick_button'),
                  onPressed: commonSorted.isNotEmpty || almostSorted.isNotEmpty
                      ? () => _pickRandom(
                            commonSorted.isNotEmpty
                                ? commonSorted
                                : almostSorted,
                          )
                      : null,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(l10n.togetherRandomPick),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('together_swipe_vote_button'),
                  onPressed: commonSorted.isNotEmpty
                      ? () {
                          session.startVote();
                          final candidates = commonSorted.take(6).map((entry) {
                            final key = '${entry.id}:${entry.type.name}';
                            final item = _mediaCache[key] ??
                                MediaItem(
                                  id: entry.id,
                                  title: 'Title ${entry.id}',
                                  overview: '',
                                  releaseDate: '',
                                  mediaType: entry.type,
                                );
                            return TogetherVoteCandidate(item: item);
                          }).toList();

                          final participantNames = [
                            l10n.togetherYouHost,
                            for (final p in session.participants) p.name,
                          ];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TogetherVotePage(
                                candidates: candidates,
                                participants: participantNames,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.how_to_vote),
                  label: Text(l10n.togetherSwipeVote),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: contrastingForeground(colors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTile({
    required MediaItem item,
    required List<String> initials,
    required AppThemeExtension colors,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.surface2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 44,
            height: 64,
            child: item.posterPath != null && item.posterPath!.isNotEmpty
                ? Image.network(
                    TmdbImageUtils.buildUrl(
                      item.posterPath,
                      size: TmdbImageSize.w185,
                    )!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.movie, color: colors.placeholder),
                  )
                : Icon(
                    item.mediaType == MediaType.tv ? Icons.tv : Icons.movie,
                    color: colors.placeholder,
                  ),
          ),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            if (item.releaseDate.length >= 4)
              Text(
                item.releaseDate.substring(0, 4),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.text2,
                ),
              ),
            if (item.voteAverage != null && item.voteAverage! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '★ ${item.voteAverage!.toStringAsFixed(1)}',
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const Spacer(),
            Wrap(
              spacing: 4,
              children: [
                for (final init in initials)
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colors.primary,
                    child: Text(
                      init,
                      style: TextStyle(
                        fontSize: 8,
                        color: contrastingForeground(colors.primary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.play_circle_outline, color: colors.success),
          tooltip: context.l10n.togetherWatchThis,
          onPressed: () => _onWatchThis(item),
        ),
      ),
    );
  }
}
