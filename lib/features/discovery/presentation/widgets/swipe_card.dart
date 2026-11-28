import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/presentation/providers/swiper_provider.dart';

/// Card displayed in the Swiper. Can represent a single movie or an entire saga.
class SwipeCard extends StatefulWidget {
  final SwipeCardCandidate candidate;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback? onSwipeUp;

  const SwipeCard({
    super.key,
    required this.candidate,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.onSwipeUp,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  double _dragDx = 0;
  double _dragDy = 0;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _animatingVertical = false;

  static const double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {
          if (_animatingVertical) {
            _dragDy = _animation.value;
          } else {
            _dragDx = _animation.value;
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDx += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (_dragDx > _swipeThreshold) {
      if (disableAnimations) {
        widget.onSwipeRight();
      } else {
        _animateOut(500, widget.onSwipeRight);
      }
    } else if (_dragDx < -_swipeThreshold) {
      if (disableAnimations) {
        widget.onSwipeLeft();
      } else {
        _animateOut(-500, widget.onSwipeLeft);
      }
    } else {
      // Rebound to center
      if (disableAnimations) {
        setState(() => _dragDx = 0);
      } else {
        _animatingVertical = false;
        _animation = Tween<double>(
          begin: _dragDx,
          end: 0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward(from: 0);
      }
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.onSwipeUp == null) return;
    setState(() {
      _dragDy = (_dragDy + details.delta.dy).clamp(-500.0, 0.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.onSwipeUp == null) return;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (_dragDy < -_swipeThreshold) {
      if (disableAnimations) {
        setState(() => _dragDy = 0);
        widget.onSwipeUp!();
      } else {
        _animateOut(-500, widget.onSwipeUp!, vertical: true);
      }
    } else {
      if (disableAnimations) {
        setState(() => _dragDy = 0);
      } else {
        _animatingVertical = true;
        _animation = Tween<double>(
          begin: _dragDy,
          end: 0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        _controller.forward(from: 0);
      }
    }
  }

  void _animateOut(
    double target,
    VoidCallback onComplete, {
    bool vertical = false,
  }) {
    _animatingVertical = vertical;
    _animation = Tween<double>(
      begin: vertical ? _dragDy : _dragDx,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward(from: 0).then((_) {
      onComplete();
      if (mounted) {
        setState(() {
          _dragDx = 0;
          _dragDy = 0;
        });
      }
    });
  }

  Widget _buildSwipeBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final error = theme.colorScheme.error;
    final success = context.appColors.success;
    final candidate = widget.candidate;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final rotation = disableAnimations
        ? 0.0
        : (_dragDx / 1000.0).clamp(-0.2, 0.2);
    final translationX = disableAnimations ? 0.0 : _dragDx;
    final translationY = disableAnimations ? 0.0 : _dragDy;

    // Overlay opacities
    final acceptOpacity = (_dragDx / _swipeThreshold).clamp(0.0, 1.0);
    final discardOpacity = (-_dragDx / _swipeThreshold).clamp(0.0, 1.0);
    final seenOpacity = widget.onSwipeUp != null
        ? (-_dragDy / _swipeThreshold).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: candidate.isSaga
          ? '${candidate.collectionName}, ${context.l10n.swiperSagaBadge(candidate.sagaItems.length)}'
          : candidate.item.title,
      customSemanticsActions: {
        CustomSemanticsAction(label: context.l10n.swiperAdd): () =>
            widget.onSwipeRight(),
        CustomSemanticsAction(label: context.l10n.swiperDiscard): () =>
            widget.onSwipeLeft(),
        if (widget.onSwipeUp != null)
          CustomSemanticsAction(label: context.l10n.commonMarkAsSeen): () =>
              widget.onSwipeUp!(),
      },
      child: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: () => MediaDetailPage.show(context, candidate.item),
        child: Transform.translate(
          offset: Offset(translationX, translationY),
          child: Transform.rotate(
            angle: rotation,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: acceptOpacity > 0
                      ? primary.withValues(alpha: acceptOpacity)
                      : discardOpacity > 0
                      ? error.withValues(alpha: discardOpacity)
                      : seenOpacity > 0
                      ? success.withValues(alpha: seenOpacity)
                      : theme.dividerColor,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  candidate.isSaga
                      ? _buildSagaContent(context, candidate)
                      : _buildMovieContent(context, candidate.item),

                  // Swipe feedback overlays
                  if (acceptOpacity > 0)
                    Positioned(
                      top: 24,
                      left: 24,
                      child: Opacity(
                        opacity: acceptOpacity,
                        child: _buildSwipeBadge(
                          icon: Icons.check,
                          label: context.l10n.swiperAdd,
                          color: primary,
                        ),
                      ),
                    ),

                  if (discardOpacity > 0)
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Opacity(
                        opacity: discardOpacity,
                        child: _buildSwipeBadge(
                          icon: Icons.close,
                          label: context.l10n.swiperDiscard,
                          color: error,
                        ),
                      ),
                    ),

                  if (seenOpacity > 0)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: seenOpacity,
                          child: _buildSwipeBadge(
                            icon: Icons.visibility_outlined,
                            label: context.l10n.seenSeen,
                            color: success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieContent(BuildContext context, MediaItem item) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.posterPath != null && item.posterPath!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: TmdbImageUtils.buildUrl(
              item.posterPath,
              size: TmdbImageSize.w780,
            )!,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.movie, size: 64),
            ),
          )
        else
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.movie, size: 64),
          ),

        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Info
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (item.releaseDate.isNotEmpty) ...[
                    Text(
                      item.releaseDate.split('-').first,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (item.voteAverage != null && item.voteAverage! > 0) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      item.voteAverage!.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (item.overview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.overview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSagaContent(BuildContext context, SwipeCardCandidate candidate) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.collections_bookmark, color: primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  candidate.collectionName ?? candidate.item.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.l10n.swiperSagaBadge(candidate.sagaItems.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: candidate.sagaItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final movie = candidate.sagaItems[index];
                final year = movie.releaseDate.isNotEmpty
                    ? movie.releaseDate.split('-').first
                    : '';
                return Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child:
                            movie.posterPath != null &&
                                movie.posterPath!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: TmdbImageUtils.buildUrl(
                                  movie.posterPath,
                                )!,
                                width: 36,
                                height: 52,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) =>
                                    const Icon(Icons.movie, size: 24),
                              )
                            : const Icon(Icons.movie, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              movie.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (year.isNotEmpty)
                              Text(
                                year,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (movie.voteAverage != null &&
                          movie.voteAverage! > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          movie.voteAverage!.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
