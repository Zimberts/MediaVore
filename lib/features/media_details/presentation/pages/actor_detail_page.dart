import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ActorDetailPage extends StatefulWidget {
  final int actorId;
  final String actorName;

  const ActorDetailPage({
    super.key,
    required this.actorId,
    required this.actorName,
  });

  @override
  State<ActorDetailPage> createState() => _ActorDetailPageState();
}

class _ActorDetailPageState extends State<ActorDetailPage> {
  late final MediaRepository _mediaRepository;
  ActorDetails? _actorDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _fetchActorDetails();
  }

  Future<void> _fetchActorDetails() async {
    try {
      final actorDetails = await _mediaRepository.getActorDetails(
        widget.actorId,
      );
      if (mounted) {
        setState(() {
          _actorDetails = actorDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load actor details: $e')),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            title: Text(_actorDetails?.name ?? widget.actorName),
            flexibleSpace: FlexibleSpaceBar(
              background:
                  _actorDetails?.profilePath != null &&
                      !Platform.environment.containsKey('FLUTTER_TEST')
                  ? CachedNetworkImage(
                      imageUrl:
                          'https://image.tmdb.org/t/p/w500${_actorDetails!.profilePath}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: colors.placeholder,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: colors.comments,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: colors.placeholder,
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: colors.comments,
                        ),
                      ),
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
                  else ...[
                    Text(
                      _actorDetails?.name ?? widget.actorName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (_actorDetails?.birthday != null)
                          _ActorIconText(
                            icon: Icons.cake,
                            text: _actorDetails!.birthday!,
                          ),
                        if (_actorDetails?.placeOfBirth != null)
                          _ActorIconText(
                            icon: Icons.location_on,
                            text: _actorDetails!.placeOfBirth!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_actorDetails?.biography != null &&
                        _actorDetails!.biography!.isNotEmpty) ...[
                      const Text(
                        'Biography',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _actorDetails!.biography!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_actorDetails != null &&
                        _actorDetails!.items.isNotEmpty) ...[
                      const Text(
                        'Known For',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildKnownForList(_actorDetails!.items),
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

  Widget _buildKnownForList(List<MediaItem> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              MediaDetailPage.show(context, item);
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          item.posterPath != null &&
                              !Platform.environment.containsKey('FLUTTER_TEST')
                          ? CachedNetworkImage(
                              imageUrl:
                                  'https://image.tmdb.org/t/p/w185${item.posterPath}',
                              fit: BoxFit.cover,
                              width: 120,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Icon(
                                item.mediaType == MediaType.tv
                                    ? Icons.tv
                                    : Icons.movie,
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  item.mediaType == MediaType.tv
                                      ? Icons.tv
                                      : Icons.movie,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActorIconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ActorIconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.appColors.comments),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
