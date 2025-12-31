import 'package:flutter/material.dart';

class WatchlistButton extends StatefulWidget {
  const WatchlistButton({super.key});

  @override
  State<WatchlistButton> createState() => _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton> {
  bool _isAdded = false;

  void _toggleWatchlist() {
    setState(() {
      _isAdded = !_isAdded;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isAdded ? 'Added to Watchlist' : 'Removed from Watchlist'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _toggleWatchlist,
      icon: Icon(_isAdded ? Icons.check : Icons.add),
      label: Text(_isAdded ? 'On Watchlist' : 'Add to Watchlist'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isAdded ? Colors.green : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
