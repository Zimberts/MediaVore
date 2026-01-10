import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscoveryProvider(),
      child: const Scaffold(
        appBar: null,
        body: DiscoveryPage(),
      ),
    );
  }
}
