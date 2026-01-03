import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';
import 'features/search/presentation/pages/search_page.dart';

Future<void> main() async {
  debugPrint('--- App Starting ---');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('WidgetsBinding initialized');
  
  try {
    try {
      debugPrint('Loading .env...');
      await dotenv.load(fileName: ".env");
      debugPrint('.env loaded');
    } catch (e) {
      debugPrint('Warning: .env file not found or failed to load: $e');
    }

    debugPrint('Initializing dependencies...');
    await init(locator);
    debugPrint('Dependencies initialized');
    
    debugPrint('Running MediaVoreApp...');
    runApp(const MediaVoreApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error during initialization: $e');
    debugPrint(stackTrace.toString());
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to start app:\n$e', 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
  }
}

class MediaVoreApp extends StatelessWidget {
  const MediaVoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            debugPrint('Creating SearchProvider...');
            final repo = locator<MediaRepository>();
            debugPrint('MediaRepository located');
            return SearchProvider(repo);
          },
        ),
      ],
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
