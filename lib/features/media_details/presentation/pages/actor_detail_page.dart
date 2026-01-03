import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/actor_details.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

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
      final actorDetails = await _mediaRepository.getActorDetails(widget.actorId);
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
        // Use addPostFrameCallback to show snackbar after build to avoid "initState" related errors
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
    final mediaQuery = MediaQuery.of(context);
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final bool isAndroidButtons = isAndroid &&
        (mediaQuery.systemGestureInsets.bottom < 8 || mediaQuery.padding.bottom > 30);

    return Scaffold(
      appBar: AppBar(
        title: Text(_actorDetails?.name ?? widget.actorName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_actorDetails?.profilePath != null && !Platform.environment.containsKey('FLUTTER_TEST'))
                    Image.network(
                      'https://image.tmdb.org/t/p/w500${_actorDetails!.profilePath}',
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 250,
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.person, size: 100),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actorDetails?.name ?? widget.actorName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (_actorDetails?.birthday != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Birthday: ${_actorDetails!.birthday}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                        if (_actorDetails?.placeOfBirth != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Place of Birth: ${_actorDetails!.placeOfBirth}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_actorDetails?.biography != null && _actorDetails!.biography!.isNotEmpty) ...[
                          Text(
                            'Biography',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _actorDetails!.biography!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_actorDetails != null && _actorDetails!.items.isNotEmpty) ...[
                          Text(
                            'Known For',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _actorDetails!.items.length,
                              itemBuilder: (context, index) {
                                final item = _actorDetails!.items[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MediaDetailPage(item: item),
                                      ),
                                    );
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
                                            child: item.posterPath != null && !Platform.environment.containsKey('FLUTTER_TEST')
                                                ? Image.network(
                                                    'https://image.tmdb.org/t/p/w185${item.posterPath}',
                                                    fit: BoxFit.cover,
                                                    width: 120,
                                                  )
                                                : Container(
                                                    color: Colors.grey[300],
                                                    child: Center(child: Icon(item.mediaType == MediaType.tv ? Icons.tv : Icons.movie)),
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
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isAndroidButtons) const SizedBox(height: 80) else const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
