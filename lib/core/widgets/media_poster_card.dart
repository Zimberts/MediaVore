import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/theme/app_typography.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:mediavore/core/widgets/media_kind.dart';

/// Where a [MediaPosterCard] writes its caption.
///
/// The design review left the choice open (prototype v1.5, "Variantes
/// d'affiche"): B is the one applied in the mock-up, C the one recommended.
enum MediaPosterVariant {
  /// Variant B: "year · length" over a dark veil at the bottom of the image;
  /// the grid keeps a fixed height.
  captionOnImage,

  /// Variant C: untouched image, title (2 lines) and caption underneath.
  captionBelow,
}

/// Variant used by every poster of the app when none is given.
///
/// Single switch for the pending decision between B and C: change it here.
const MediaPosterVariant kDefaultPosterVariant =
    MediaPosterVariant.captionOnImage;

/// How much of a title has been watched or read.
enum MediaSeenState { none, inProgress, seen }

/// Minimal display model of a poster, shared by films, series and books.
@immutable
class MediaPosterData {
  const MediaPosterData({
    required this.title,
    required this.kind,
    this.imageUrl,
    this.image,
    this.caption,
    this.seen = MediaSeenState.none,
    this.rating,
    this.liked = false,
  });

  final String title;
  final MediaKind kind;

  /// Network image, loaded through the image cache.
  final String? imageUrl;

  /// Image to use instead of [imageUrl] (local cover, tests).
  final ImageProvider? image;

  /// One line under the title: "year · length", seasons or pages.
  final String? caption;

  final MediaSeenState seen;

  /// Average rating out of 10; hidden when null or 0.
  final double? rating;

  /// Marked as liked: a small heart next to the caption.
  final bool liked;

  bool get hasImage => image != null || imageUrl != null;
}

/// Poster of a film or a series, or cover of a book (drawn with a spine).
///
/// Text never sits directly on the image: the caption is written over a dark
/// veil, and the title is only drawn when the image is missing (a real poster
/// already carries it). The title always stays in the accessibility label.
class MediaPosterCard extends StatelessWidget {
  const MediaPosterCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.variant = kDefaultPosterVariant,
    this.compact = false,
    this.showType = true,
    this.selected,
    this.action,
  });

  final MediaPosterData data;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final MediaPosterVariant variant;

  /// Thumbnail for list rows: image and seen check only, no text.
  final bool compact;

  /// Shows the media type badge.
  final bool showType;

  /// Selection mode: `null` outside of it, otherwise whether this poster is
  /// part of the selection.
  final bool? selected;

  /// Optional control in the bottom end corner (e.g. a watchlist toggle). It
  /// gets a 48 dp touch area and its own semantics.
  final Widget? action;

  /// Width / height of the image.
  static const double aspectRatio = 2 / 3;

  /// Share of the height covered by the veil, from the bottom.
  static const double scrimHeightFactor = 0.46;

  /// Opacity of the veil at the bottom edge.
  static const double scrimMaxOpacity = 0.86;

  /// Under this width the caption and the rating are dropped (4 columns).
  static const double minWidthForDetails = 92;

  /// Text and icons drawn over an image or its veil.
  static const Color onImage = Color(0xFFFFFFFF);

  /// Background of the type and rating badges: black at 72 %.
  static const Color badgeBackground = Color(0xB8000000);

  @visibleForTesting
  static const Key scrimKey = Key('mediaPosterCard.scrim');

  @visibleForTesting
  static const Key captionKey = Key('mediaPosterCard.caption');

  @visibleForTesting
  static const Key titleKey = Key('mediaPosterCard.title');

  /// Height of the text block of [MediaPosterVariant.captionBelow].
  static double captionBelowExtent(TextScaler textScaler) =>
      5 + textScaler.scale(12) * 1.2 * 2 + 1 + textScaler.scale(11) * 1.3 + 2;

  /// Grid delegate whose cells fit a poster of [variant] exactly.
  ///
  /// [width] is the width available to the grid content (padding excluded).
  static SliverGridDelegate gridDelegate({
    required BuildContext context,
    required double width,
    required int crossAxisCount,
    double spacing = 10,
    MediaPosterVariant variant = kDefaultPosterVariant,
  }) {
    final cellWidth =
        ((width - spacing * (crossAxisCount - 1)) / crossAxisCount).clamp(
          1.0,
          double.infinity,
        );
    var extent = cellWidth / aspectRatio;
    if (variant == MediaPosterVariant.captionBelow) {
      extent += captionBelowExtent(MediaQuery.textScalerOf(context));
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: extent,
    );
  }

  String _semanticLabel(AppLocalizations l10n) {
    final rating = data.rating;
    return [
      data.title,
      data.kind.label(l10n),
      if (data.caption != null && data.caption!.isNotEmpty) data.caption!,
      if (rating != null && rating > 0)
        l10n.posterRating(rating.toStringAsFixed(1)),
      if (data.seen == MediaSeenState.seen) l10n.seenSeen,
      if (data.seen == MediaSeenState.inProgress) l10n.posterInProgress,
      if (data.liked) l10n.posterLiked,
    ].join(', ');
  }

  BorderRadius get _radius {
    if (data.kind == MediaKind.book) {
      return BorderRadius.horizontal(
        left: Radius.circular(compact ? 2 : 3),
        right: Radius.circular(compact ? 5 : 8),
      );
    }
    return BorderRadius.circular(compact ? 6 : 12);
  }

  @override
  Widget build(BuildContext context) {
    final below = !compact && variant == MediaPosterVariant.captionBelow;
    final selected = this.selected;
    final action = this.action;

    Widget poster = AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) => _PosterFace(
          data: data,
          compact: compact,
          showType: showType && selected == null,
          selected: selected,
          captionOnImage: !below,
          detailed: constraints.maxWidth >= minWidthForDetails,
          radius: _radius,
          reserveAction: action != null,
        ),
      ),
    );

    if (below) {
      poster = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          poster,
          Flexible(child: _CaptionBelow(data: data)),
        ],
      );
    }

    final card = Semantics(
      button: onTap != null,
      selected: selected,
      label: _semanticLabel(context.l10n),
      // The children are replaced by the label: re-expose their actions.
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: _radius,
          child: poster,
        ),
      ),
    );

    if (action == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          end: 0,
          // Bottom corner of the image, also when the caption is below.
          top: 0,
          start: 0,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: SizedBox(
                width: kMinTapTarget,
                height: kMinTapTarget,
                child: action,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PosterFace extends StatelessWidget {
  const _PosterFace({
    required this.data,
    required this.compact,
    required this.showType,
    required this.selected,
    required this.captionOnImage,
    required this.detailed,
    required this.radius,
    required this.reserveAction,
  });

  final MediaPosterData data;
  final bool compact;
  final bool showType;
  final bool? selected;
  final bool captionOnImage;
  final bool detailed;
  final BorderRadius radius;
  final bool reserveAction;

  bool get _showCaption =>
      !compact &&
      captionOnImage &&
      detailed &&
      (data.caption?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final image = data.image;
    final url = data.imageUrl;

    Widget face;
    if (image != null) {
      face = Image(
        image: image,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            frame == null && !wasSynchronouslyLoaded
            ? _withoutImage(context)
            : _withImage(context, child),
        errorBuilder: (context, error, stackTrace) => _withoutImage(context),
      );
    } else if (url != null) {
      face = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        imageBuilder: (context, provider) => _withImage(
          context,
          Image(image: provider, fit: BoxFit.cover, excludeFromSemantics: true),
        ),
        placeholder: (context, url) => _withoutImage(context),
        errorWidget: (context, url, error) => _withoutImage(context),
      );
    } else {
      face = _withoutImage(context);
    }

    return DecoratedBox(
      // Selection ring, drawn outside the clip so that it stays crisp.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: selected == true
            ? Border.all(color: colors.primary, width: 3)
            : null,
      ),
      child: ClipRRect(borderRadius: radius, child: face),
    );
  }

  /// Loaded image: veil, caption in white, no title.
  Widget _withImage(BuildContext context, Widget image) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (_showCaption)
          const Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: MediaPosterCard.scrimHeightFactor,
              child: DecoratedBox(
                key: MediaPosterCard.scrimKey,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color.from(
                        alpha: MediaPosterCard.scrimMaxOpacity,
                        red: 0,
                        green: 0,
                        blue: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (data.kind == MediaKind.book) const _Spine(),
        ..._badges(context),
        if (_showCaption)
          PositionedDirectional(
            start: 8,
            end: reserveAction ? kMinTapTarget : 8,
            bottom: 8,
            child: _caption(context, MediaPosterCard.onImage),
          ),
      ],
    );
  }

  /// No image (missing, loading or failed): tinted fill carrying the title.
  Widget _withoutImage(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: data.kind.background(colors)),
        if (data.kind == MediaKind.book) const _Spine(),
        if (compact)
          Center(
            child: Icon(
              data.kind.icon,
              size: 20,
              color: data.kind.color(colors),
            ),
          )
        else
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              data.kind == MediaKind.book ? 12 : 8,
              34,
              8,
              8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    data.title,
                    key: MediaPosterCard.titleKey,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontFamily: AppFonts.heading,
                      fontFamilyFallback: const [AppFonts.body],
                      fontSize: detailed ? 13 : 11,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: colors.text,
                    ),
                  ),
                ),
                if (_showCaption) ...[
                  const SizedBox(height: 3),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: reserveAction ? kMinTapTarget - 8 : 0,
                    ),
                    child: _caption(context, colors.text2),
                  ),
                ],
              ],
            ),
          ),
        ..._badges(context),
      ],
    );
  }

  Widget _caption(BuildContext context, Color color) {
    final text = _captionText(context, color);
    if (!data.liked) return text;
    return Row(
      children: [
        Icon(Icons.favorite, size: 11, color: color),
        const SizedBox(width: 4),
        Expanded(child: text),
      ],
    );
  }

  Widget _captionText(BuildContext context, Color color) {
    return Text(
      data.caption!,
      key: MediaPosterCard.captionKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: color,
      ),
    );
  }

  List<Widget> _badges(BuildContext context) {
    final rating = data.rating;
    final inset = compact ? 3.0 : 6.0;
    final seenSize = compact ? 16.0 : 20.0;

    return [
      if (data.liked && !compact && !_showCaption)
        const PositionedDirectional(
          start: 6,
          bottom: 6,
          child: _Badge(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.favorite,
              size: 12,
              color: MediaPosterCard.onImage,
            ),
          ),
        ),

      PositionedDirectional(
        top: inset,
        start: inset,
        end: inset,
        child: Row(
          children: [
            if (selected != null)
              _SelectionMark(selected: selected!)
            else if (showType && !compact) ...[
              _Badge(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  data.kind.icon,
                  size: 12,
                  color: MediaPosterCard.onImage,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (selected == null && data.seen != MediaSeenState.none)
              _SeenMark(state: data.seen, size: seenSize),
            if (!compact && detailed && rating != null && rating > 0)
              // Shrinks rather than overflows next to the other badges.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _Badge(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: MediaPosterCard.onImage,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1,
                              color: MediaPosterCard.onImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MediaPosterCard.badgeBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

/// Seen check: a white disc at the top of the poster.
class _SeenMark extends StatelessWidget {
  const _SeenMark({required this.state, required this.size});

  final MediaSeenState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: MediaPosterCard.onImage,
        shape: BoxShape.circle,
      ),
      child: Icon(
        state == MediaSeenState.seen ? Icons.check : Icons.more_horiz,
        size: size * 0.7,
        color: const Color(0xFF111111),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle),
      padding: const EdgeInsets.all(1),
      child: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 20,
        color: selected ? colors.primary : colors.stateOutline,
      ),
    );
  }
}

/// Spine of a book cover, along the start edge.
class _Spine extends StatelessWidget {
  const _Spine();

  @override
  Widget build(BuildContext context) {
    return const PositionedDirectional(
      start: 0,
      top: 0,
      bottom: 0,
      width: 6,
      child: ColoredBox(color: Color(0x47000000)),
    );
  }
}

class _CaptionBelow extends StatelessWidget {
  const _CaptionBelow({required this.data});

  final MediaPosterData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final caption = data.caption;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              data.title,
              key: MediaPosterCard.titleKey,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                letterSpacing: 0,
                color: colors.text,
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                caption,
                key: MediaPosterCard.captionKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.3,
                  letterSpacing: 0,
                  color: colors.text2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
