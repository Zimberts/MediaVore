import 'package:flutter/material.dart';
import 'package:mediavore/features/search/presentation/providers/saved_movies_provider.dart';
import 'package:provider/provider.dart';

class SavedMoviesPage extends StatelessWidget {
  const SavedMoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Movies'),
      ),
      body: Consumer<SavedMoviesProvider>(
        builder: (context, savedMoviesProvider, child) {
          final savedMovies = savedMoviesProvider.savedMovies;
          if (savedMovies.isEmpty) {
            return const Center(child: Text('No movies saved yet.'));
          }
          return ListView.builder(
            itemCount: savedMovies.length,
            itemBuilder: (context, index) {
              final movie = savedMovies[index];
              return ListTile(
                leading: movie.posterPath != null
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.movie),
                      )
                    : const Icon(Icons.movie),
                title: Text(movie.title),
                subtitle: Text(
                  movie.releaseDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    savedMoviesProvider.toggleMovieSaved(movie);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
