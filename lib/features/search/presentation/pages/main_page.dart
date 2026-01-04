import 'package:flutter/material.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<GlobalKey<SavedMediaPageState>> _savedMediaPageKeys = [
    GlobalKey<SavedMediaPageState>(), // Index 0 not used for SavedMediaPage but keep for index alignment
    GlobalKey<SavedMediaPageState>(),
  ];

  void _onTap(int index) {
    if (_currentIndex == index) {
      final navigator = _navigatorKeys[index].currentState;
      if (navigator != null) {
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
        if (index == 0) {
          context.read<SearchProvider>().requestReset();
        } else if (index == 1) {
          _savedMediaPageKeys[1].currentState?.loadSavedMedia();
        }
      }
    } else {
      if (index == 1) {
        // When switching TO the watchlist tab, refresh the list
        _savedMediaPageKeys[1].currentState?.loadSavedMedia();
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildNavigator(0, const SearchPage()),
            _buildNavigator(1, SavedMediaPage(key: _savedMediaPageKeys[1])),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Watchlist',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }
}
