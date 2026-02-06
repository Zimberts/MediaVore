import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mediavore/features/media_details/presentation/pages/notification_center_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // Default to SavedMediaPage
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  static const List<Widget> _pages = [
    SearchPage(),
    SavedMediaPage(),
    SeenHistoryPage(),
    NotificationCenterPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleLink(initialLink);
      }
    } catch (_) {}

    // Handle subsequent links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.path == '/share' || (uri.scheme == 'mediavore' && uri.host == 'share')) {
      final name = uri.queryParameters['name'];
      final itemsStr = uri.queryParameters['items'];

      if (name != null && itemsStr != null) {
        final items = itemsStr.split(',');
        _showImportDialog(name, items);
      }
    }
  }

  void _showImportDialog(String suggestedName, List<String> entries) {
    final controller = TextEditingController(text: suggestedName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to import a list with ${entries.length} items.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'List Name', hintText: 'Enter name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final provider = context.read<SearchProvider>();
              final navigator = Navigator.of(context);
              await provider.importList(controller.text, entries);
              if (mounted) {
                navigator.pop();
                setState(() => _selectedIndex = 1);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'My Lists'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Seen'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
