import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/top_scrim_gradient.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class PersonPage extends StatefulWidget {
  final int personId;
  final String personName;
  final bool isSheet;
  final ScrollController? scrollController;

  const PersonPage({
    super.key,
    required this.personId,
    required this.personName,
    this.isSheet = false,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required int personId,
    required String personName,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PersonPage(
          personId: personId,
          personName: personName,
        ),
      ),
    );
  }

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  late final MediaRepository _mediaRepository;
  PersonDetails? _personDetails;
  bool _isLoading = true;
  bool _bioExpanded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final details = await _mediaRepository.getActorDetails(widget.personId);
      if (mounted) {
        setState(() {
          _personDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '$e';
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.actorLoadFailed('$e'))),
            );
          }
        });
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final l10n = context.l10n;

    SearchProvider? searchProvider;
    try {
      searchProvider = context.watch<SearchProvider?>();
    } catch (_) {
      searchProvider = null;
    }
    final seenItems = searchProvider?.seenItems ?? const <SeenItem>[];

    final details = _personDetails;
    final uniqueItems = <int, MediaItem>{};
    if (details != null) {
      for (final item in [...details.items, ...details.crewItems]) {
        uniqueItems[item.id] = item;
      }
    }
    final totalCount = uniqueItems.length;
    final seenCount = uniqueItems.values
        .where((item) => seenItems.any((s) => s.tmdbId == item.id))
        .length;

    final name = details?.name ?? widget.personName;
    final profilePath = details?.profilePath;

    return Scaffold(
      backgroundColor: widget.isSheet ? Colors.transparent : null,
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            title: Text(name),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  profilePath != null &&
                          !Platform.environment.containsKey('FLUTTER_TEST')
                      ? CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/w500$profilePath',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              _buildInitialsPlaceholder(name, colors),
                        )
                      : _buildInitialsPlaceholder(name, colors),
                  const TopScrimGradient(),
                ],
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null && details == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: colors.text2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.personOfflineNoData,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.text2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: _fetchDetails,
                              child: Text(l10n.commonRetry),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(name, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (totalCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              l10n.personSeenCount(seenCount, totalCount),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (details?.birthday != null)
                          _PersonIconText(
                            icon: Icons.cake,
                            text: details!.birthday!,
                          ),
                        if (details?.placeOfBirth != null)
                          _PersonIconText(
                            icon: Icons.location_on,
                            text: details!.placeOfBirth!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (details?.biography != null &&
                        details!.biography!.trim().isNotEmpty) ...[
                      SectionHeader(title: l10n.actorBiography),
                      const SizedBox(height: 8),
                      Text(
                        details.biography!,
                        maxLines: _bioExpanded ? null : 4,
                        overflow: _bioExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _bioExpanded = !_bioExpanded),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            _bioExpanded
                                ? l10n.detailReadLess
                                : l10n.detailReadMore,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (details != null && details.crewItems.isNotEmpty) ...[
                      SectionHeader(title: l10n.personDirecting),
                      const SizedBox(height: 12),
                      _FilmographyGrid(
                        items: details.crewItems,
                        seenItems: seenItems,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (details != null && details.items.isNotEmpty) ...[
                      SectionHeader(
                        title: details.crewItems.isNotEmpty
                            ? l10n.personActing
                            : l10n.actorKnownFor,
                      ),
                      const SizedBox(height: 12),
                      _FilmographyGrid(
                        items: details.items,
                        seenItems: seenItems,
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 40),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsPlaceholder(String name, AppThemeExtension colors) {
    return Container(
      color: colors.placeholder,
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: colors.text2,
          ),
        ),
      ),
    );
  }
}

class _FilmographyGrid extends StatelessWidget {
  final List<MediaItem> items;
  final List<SeenItem> seenItems;

  const _FilmographyGrid({
    required this.items,
    required this.seenItems,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.52,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSeen = seenItems.any((s) => s.tmdbId == item.id);
        final year = item.releaseDate.length >= 4
            ? item.releaseDate.substring(0, 4)
            : '';
        final colors = context.appColors;
        final theme = Theme.of(context);

        return GestureDetector(
          onTap: () => MediaDetailPage.show(context, item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.posterPath != null &&
                              !Platform.environment.containsKey('FLUTTER_TEST')
                          ? CachedNetworkImage(
                              imageUrl:
                                  'https://image.tmdb.org/t/p/w185${item.posterPath}',
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: colors.placeholder),
                              errorWidget: (context, url, error) => Container(
                                color: colors.placeholder,
                                child: Icon(
                                  item.mediaType == MediaType.tv
                                      ? Icons.tv
                                      : Icons.movie,
                                ),
                              ),
                            )
                          : Container(
                              color: colors.placeholder,
                              child: Icon(
                                item.mediaType == MediaType.tv
                                    ? Icons.tv
                                    : Icons.movie,
                              ),
                            ),
                      if (isSeen)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.check_circle,
                              color: colors.success,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (year.isNotEmpty)
                Text(
                  year,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.text2,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PersonIconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PersonIconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.appColors.text2),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
