import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/di/injection.config.dart';
import 'features/search/presentation/pages/search_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await locator.init(environment: Environment.prod);
  runApp(const MediaVoreApp());
}

class MediaVoreApp extends StatelessWidget {
  const MediaVoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaVore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}
