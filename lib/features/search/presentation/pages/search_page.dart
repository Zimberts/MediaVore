import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/discovery/presentation/pages/discovery_page.dart';
import 'package:mediavore/features/discovery/presentation/providers/discovery_provider.dart';

class SearchPage extends StatelessWidget {
  final ValueListenable<int> searchTrigger;

  const SearchPage({super.key, required this.searchTrigger});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscoveryProvider(),
      child: Scaffold(
        appBar: null,
        body: DiscoveryPage(searchTrigger: searchTrigger),
      ),
    );
  }
}
