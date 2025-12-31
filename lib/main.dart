import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/features/search/presentation/providers/saved_movies_provider.dart';
import 'package:provider/provider.dart';
import 'features/search/presentation/pages/search_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MediaVoreApp());
}

class MediaVoreApp extends StatelessWidget {
  const MediaVoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SavedMoviesProvider(),
      child: MaterialApp(
        title: 'MediaVore',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SearchPage(),
      ),
    );
  }
}
