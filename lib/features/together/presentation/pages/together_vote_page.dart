import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/achievements/presentation/providers/achievement_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/together/presentation/models/together_vote_engine.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:provider/provider.dart';

/// Full-screen voting flow: participants pass the phone and vote Yes/No on candidate cards.
///
/// Tab bar is hidden during voting. Accidental exit is guarded by a confirmation dialog.
class TogetherVotePage extends StatefulWidget {
  const TogetherVotePage({
    super.key,
    required this.candidates,
    required this.participants,
    this.engine,
  });

  final List<TogetherVoteCandidate> candidates;
  final List<String> participants;
  final TogetherVoteEngine? engine;

  @override
  State<TogetherVotePage> createState() => _TogetherVotePageState();
}

class _TogetherVotePageState extends State<TogetherVotePage> {
  late final TogetherVoteEngine _engine;
  late final bool _ownsEngine;
  double _dragDx = 0.0;
  bool _hasIncrementedChoice = false;

  @override
  void initState() {
    super.initState();
    _ownsEngine = widget.engine == null;
    _engine =
        widget.engine ??
        TogetherVoteEngine(
          candidates: widget.candidates,
          participants: widget.participants,
        );
    _engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  void _onEngineChanged() {
    if (_engine.isFinished && !_hasIncrementedChoice) {
      _hasIncrementedChoice = true;
      context.read<TogetherSessionProvider>().incrementTogetherChoicesCount();
      try {
        context.read<AchievementProvider>().refresh();
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _confirmLeaveVote() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.togetherLeaveVoteTitle),
        content: Text(l10n.togetherLeaveVoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TogetherSessionProvider>().endVote();
              Navigator.pop(context);
            },
            child: Text(l10n.togetherLeaveVoteButton),
          ),
        ],
      ),
    );
  }

  void _onWatchThis(MediaItem item) {
    final l10n = context.l10n;
    final session = context.read<TogetherSessionProvider>();

    showAppMessage(
      l10n.togetherWatchingToast(item.title),
      actionLabel: l10n.commonUndo,
      onAction: () {},
    );

    session.reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MediaDetailPage(item: item)),
    );
  }

  void _onReviewList() {
    final session = context.read<TogetherSessionProvider>();
    session.endVote(keepVotes: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmLeaveVote();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.l10n.togetherLeaveVoteTitle,
            onPressed: _confirmLeaveVote,
          ),
          title: _engine.isFinished
              ? Text(context.l10n.togetherTonightChoice)
              : !_engine.isTransition
              ? Text(
                  context.l10n.togetherVoteProgress(
                    _engine.currentCandidateIndex + 1,
                    _engine.candidates.length,
                  ),
                )
              : null,
          centerTitle: true,
          actions: [
            if (!_engine.isFinished && !_engine.isTransition)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Chip(
                    label: Text(
                      _engine.currentParticipant,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _engine.isFinished
              ? _buildWinnerView(context)
              : _engine.isTransition
              ? _buildTransitionView(context)
              : _buildVotingCardView(context),
        ),
      ),
    );
  }

  Widget _buildTransitionView(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final isHost = _engine.isHostTurn;
    final voterName = _engine.currentParticipant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: isHost ? colors.primary : colors.duo,
              child: Icon(
                isHost ? Icons.person : Icons.phone_android,
                size: 48,
                color: isHost
                    ? contrastingForeground(colors.primary)
                    : contrastingForeground(colors.duo),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHost
                  ? l10n.togetherYourTurn
                  : l10n.togetherPassPhone(voterName),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.togetherVoteLimitNotice(_engine.candidates.length),
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('together_start_turn_button'),
                onPressed: () => _engine.startTurn(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: contrastingForeground(colors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isHost
                      ? l10n.togetherHostStartVote
                      : l10n.togetherParticipantStartVote,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingCardView(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final candidate = _engine.currentCandidate;
    final item = candidate.item;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() => _dragDx += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                if (_dragDx > 80) {
                  _engine.castVote(true);
                } else if (_dragDx < -80) {
                  _engine.castVote(false);
                }
                setState(() => _dragDx = 0.0);
              },
              child: Transform.translate(
                offset: Offset(_dragDx, 0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _dragDx > 40
                          ? colors.success
                          : _dragDx < -40
                          ? colors.danger
                          : colors.border,
                      width: _dragDx.abs() > 40 ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child:
                            item.posterPath != null &&
                                item.posterPath!.isNotEmpty
                            ? Image.network(
                                TmdbImageUtils.buildUrl(
                                  item.posterPath,
                                  size: TmdbImageSize.w500,
                                )!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: colors.surface2,
                                  child: Icon(
                                    item.mediaType == MediaType.tv
                                        ? Icons.tv
                                        : Icons.movie,
                                    size: 64,
                                    color: colors.placeholder,
                                  ),
                                ),
                              )
                            : Container(
                                color: colors.surface2,
                                child: Icon(
                                  item.mediaType == MediaType.tv
                                      ? Icons.tv
                                      : Icons.movie,
                                  size: 64,
                                  color: colors.placeholder,
                                ),
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.voteAverage != null &&
                                      item.voteAverage! > 0) ...[
                                    const SizedBox(width: 8),
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
                              if (item.releaseDate.length >= 4) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.releaseDate.substring(0, 4),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.text2,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  item.overview,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.text,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Oui / Non action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Non button
              FloatingActionButton.large(
                key: const Key('together_vote_no'),
                heroTag: 'together_vote_no',
                tooltip: l10n.togetherVoteNo,
                onPressed: () => _engine.castVote(false),
                backgroundColor: colors.danger,
                foregroundColor: contrastingForeground(colors.danger),
                shape: const CircleBorder(),
                child: const Icon(Icons.close, size: 36),
              ),
              const SizedBox(width: 32),
              // Oui button
              FloatingActionButton.large(
                key: const Key('together_vote_yes'),
                heroTag: 'together_vote_yes',
                tooltip: l10n.togetherVoteYes,
                onPressed: () => _engine.castVote(true),
                backgroundColor: colors.success,
                foregroundColor: contrastingForeground(colors.success),
                shape: const CircleBorder(),
                child: const Icon(Icons.check, size: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerView(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final results = _engine.getResults();

    if (results.isEmpty) {
      return Center(child: Text(l10n.togetherEmptyCommonTitle));
    }

    final winner = results.first;
    final otherResults = results.skip(1).toList();
    final isUnanimous = _engine.isUnanimous(winner);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Top Winner Banner Card
        Card(
          elevation: 6,
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.primary, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (winner.candidate.item.posterPath != null &&
                  winner.candidate.item.posterPath!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    TmdbImageUtils.buildUrl(
                      winner.candidate.item.posterPath,
                      size: TmdbImageSize.w780,
                    )!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: colors.surface2,
                      child: Icon(
                        Icons.movie,
                        size: 48,
                        color: colors.placeholder,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Unanimous or vote count pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUnanimous
                                ? colors.warning
                                : colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUnanimous
                                ? l10n.togetherUnanimousVote
                                : l10n.togetherVoteCountFraction(
                                    winner.approvalCount,
                                    _engine.participants.length,
                                  ),
                            style: TextStyle(
                              color: isUnanimous
                                  ? contrastingForeground(colors.warning)
                                  : colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (winner.isTied) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.duo.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.togetherTieBadge,
                              style: TextStyle(
                                color: colors.duo,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (winner.candidate.item.voteAverage != null &&
                            winner.candidate.item.voteAverage! > 0)
                          Text(
                            '★ ${winner.candidate.item.voteAverage!.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: colors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      winner.candidate.item.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (winner.candidate.item.releaseDate.length >= 4) ...[
                      const SizedBox(height: 4),
                      Text(
                        winner.candidate.item.releaseDate.substring(0, 4),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.text2,
                        ),
                      ),
                    ],
                    if (winner.candidate.item.overview.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        winner.candidate.item.overview,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.text,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        ElevatedButton.icon(
          key: const Key('together_watch_this_button'),
          onPressed: () => _onWatchThis(winner.candidate.item),
          icon: const Icon(Icons.play_circle_fill),
          label: Text(l10n.togetherWatchThis),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: colors.success,
            foregroundColor: contrastingForeground(colors.success),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('together_review_list_button'),
          onPressed: _onReviewList,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(l10n.togetherReviewList),
        ),

        // Other candidates ranked
        if (otherResults.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(title: l10n.togetherOtherTitles),
          const SizedBox(height: 8),
          for (var i = 0; i < otherResults.length; i++)
            _buildRankedTile(
              rank: i + 2,
              result: otherResults[i],
              colors: colors,
              theme: theme,
              l10n: l10n,
            ),
        ],
      ],
    );
  }

  Widget _buildRankedTile({
    required int rank,
    required TogetherVoteResultItem result,
    required AppThemeExtension colors,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    final item = result.candidate.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.surface2,
      child: ListTile(
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: colors.border,
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.text,
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
                style: theme.textTheme.bodySmall?.copyWith(color: colors.text2),
              ),
            if (item.voteAverage != null && item.voteAverage! > 0) ...[
              const SizedBox(width: 8),
              Text(
                '★ ${item.voteAverage!.toStringAsFixed(1)}',
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            '${result.approvalCount} / ${_engine.participants.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
