import 'package:flutter/material.dart';
import 'package:mediavore/features/search/presentation/pages/search_page.dart';
import 'package:mediavore/features/search/presentation/pages/saved_media_page.dart';
import 'package:mediavore/features/media_details/presentation/pages/seen_history_page.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _StatefulNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootPage;

  const _StatefulNavigator({required this.navigatorKey, required this.rootPage});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<GlobalKey<SavedMediaPageState>> _savedMediaPageKeys = [
    GlobalKey<SavedMediaPageState>(), // Index 0 not used for SavedMediaPage
    GlobalKey<SavedMediaPageState>(), // Index 1
    GlobalKey<SavedMediaPageState>(), // Index 2 not used
  ];

  void _onTap(int index) {
    if (_currentIndex == index) {
      final navigator = _navigatorKeys[index].currentState;
      if (navigator != null) {
        if (index == 0) {
          if (navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          }
          context.read<SearchProvider>().requestReset();
        } else if (index == 1) {
          if (navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          } else {
            _savedMediaPageKeys[1].currentState?.resetToDefault();
          }
        } else if (index == 2) {
          if (navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          }
        }
      }
    } else {
      if (index == 1) {
        _savedMediaPageKeys[1].currentState?.loadSavedMedia();
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<SearchProvider>().isOffline;

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
        body: Column(
          children: [
            if (isOffline)
              Container(
                color: Colors.orange,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const SafeArea(
                  bottom: false,
                  child: Text(
                    'Offline Mode - Using locally saved data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 12, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _StatefulNavigator(navigatorKey: _navigatorKeys[0], rootPage: const SearchPage()),
                  _StatefulNavigator(navigatorKey: _navigatorKeys[1], rootPage: SavedMediaPage(key: _savedMediaPageKeys[1])),
                  _StatefulNavigator(navigatorKey: _navigatorKeys[2], rootPage: const SeenHistoryPage()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Watchlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.visibility),
              label: 'Seen',
            ),
          ],
        ),
      ),
    );
  }
}
