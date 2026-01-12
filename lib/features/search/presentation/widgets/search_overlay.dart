import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';

class SearchOverlay extends StatefulWidget {
  final bool initialScan;
  const SearchOverlay({super.key, this.initialScan = false});

  @override
  State<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialScan) {
      _isScanning = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<SearchProvider>();
      provider.searchMedia(value);
    });
  }

  void _handleBarcode(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isScanning = false);
        _controller.text = code;
        context.read<SearchProvider>().searchMedia(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isScanning 
          ? const Text('Scan Barcode')
          : TextField(
              controller: _controller,
              autofocus: !widget.initialScan,
              decoration: const InputDecoration(
                hintText: 'Search movies, TV shows...',
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
            ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
              });
            },
          ),
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                context.read<SearchProvider>().clearSearch();
              },
            ),
        ],
      ),
      body: _isScanning
          ? MobileScanner(
              onDetect: _handleBarcode,
            )
          : Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = provider.items;
                if (items.isEmpty && _controller.text.isNotEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: item.posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w92${item.posterPath}',
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.movie),
                            )
                          : const Icon(Icons.movie),
                      title: Text(item.title),
                      subtitle: Text(item.releaseDate),
                      onTap: () {
                        MediaDetailPage.show(context, item);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
