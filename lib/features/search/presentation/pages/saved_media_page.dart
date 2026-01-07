import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SavedMediaPage extends StatefulWidget {
  const SavedMediaPage({super.key});

  @override
  State<SavedMediaPage> createState() => SavedMediaPageState();
}

enum SortMethod { manual, releaseDate, releaseDateDesc, shuffle }

class SavedMediaPageState extends State<SavedMediaPage> {
  late final MediaRepository _mediaRepository;
  String _selectedList = 'watchlist';
  Future<List<MediaItem>>? _savedMediaFuture;
  bool _isRefreshing = false;
  SortMethod _sortMethod = SortMethod.manual;
  List<MediaItem> _currentItems = [];
  final GlobalKey _qrKey = GlobalKey();
  Uint8List? _croppedLogoBytes;

  @override
  void initState() {
    super.initState();
    _mediaRepository = locator<MediaRepository>();
    _prepareCroppedLogo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SearchProvider>().loadLists();
        loadSavedMedia();
      }
    });
  }

  /// Programmatically crops the white space from the app icon to make the logo 
  /// appear larger in the QR code.
  Future<void> _prepareCroppedLogo() async {
    try {
      final data = await rootBundle.load('assets/icon/app_icon.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final fullImage = frame.image;

      // Crop to the central 58% where the character is located
      final double size = fullImage.width.toDouble();
      final double cropSize = size * 0.58; 
      final double offset = (size - cropSize) / 2;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      canvas.drawImageRect(
        fullImage,
        Rect.fromLTWH(offset, offset, cropSize, cropSize),
        Rect.fromLTWH(0, 0, cropSize, cropSize),
        ui.Paint()..isAntiAlias = true..filterQuality = ui.FilterQuality.high,
      );

      final croppedImage = await recorder.endRecording().toImage(cropSize.toInt(), cropSize.toInt());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (mounted) {
        setState(() {
          _croppedLogoBytes = byteData?.buffer.asUint8List();
        });
      }
    } catch (e) {
      debugPrint('Error cropping logo: $e');
    }
  }

  Future<void> loadSavedMedia({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    if (forceRefresh) {
      context.read<SearchProvider>().setOffline(false);
    }

    setState(() {
      _savedMediaFuture = _fetchSavedMedia();
    });
  }

  void resetToDefault() {
    if (_selectedList != 'watchlist') {
      setState(() {
        _selectedList = 'watchlist';
      });
      loadSavedMedia();
    }
  }

  Future<List<MediaItem>> _fetchSavedMedia() async {
    final provider = context.read<SearchProvider>();
    final entries = await _mediaRepository.getListEntries(_selectedList);
    final localItems = await _mediaRepository.getListPreviews(_selectedList, limit: 1000);

    List<MediaItem> items;
    if (provider.isOffline) {
      items = entries.map((entry) {
        final parts = entry.split(':');
        final id = int.parse(parts[0]);
        final typeStr = parts.length > 1 ? parts[1] : 'movie';
        final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;
        
        final local = localItems.firstWhere(
          (l) => l.id == id && l.type == type.name,
          orElse: () => MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
        );
        
        return MediaItem(
          id: local.id,
          title: local.title,
          overview: '', 
          releaseDate: '', 
          mediaType: type,
          posterPath: local.posterPath,
        );
      }).toList();
    } else {
      final itemFutures = entries.map((entry) async {
        try {
          final parts = entry.split(':');
          final id = int.parse(parts[0]);
          final typeStr = parts.length > 1 ? parts[1] : 'movie';
          final type = typeStr == 'tv' ? MediaType.tv : MediaType.movie;
              
          try {
            final details = await provider.getMediaDetails(id, type);
            return details.item;
          } catch (e) {
            final local = localItems.firstWhere(
              (l) => l.id == id && l.type == typeStr,
              orElse: () => MediaItemPreview(id: id, title: 'Unknown', type: typeStr),
            );
            return MediaItem(
              id: local.id,
              title: local.title,
              overview: '', 
              releaseDate: '', 
              mediaType: type,
              posterPath: local.posterPath,
            );
          }
        } catch (e) {
          return const MediaItem(id: 0, title: 'Error', overview: '', releaseDate: '');
        }
      });
      items = (await Future.wait(itemFutures)).where((item) => item.id != 0).toList();
    }
    
    if (mounted) {
      provider.loadAllSeenStatus();
    }
    _currentItems = items;
    return items;
  }

  Future<void> _removeItem(MediaItem item) async {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    await provider.toggleInList(item, _selectedList);
    loadSavedMedia();
  }

  List<MediaItem> _getFilteredAndSortedItems(List<MediaItem> items, SettingsProvider settings) {
    List<MediaItem> result = List.from(items);
    
    if (settings.hideNonReleased) {
      final now = DateTime.now();
      result = result.where((item) {
        if (item.releaseDate.isEmpty) return false;
        final rel = DateTime.tryParse(item.releaseDate);
        return rel != null && rel.isBefore(now);
      }).toList();
    }

    switch (_sortMethod) {
      case SortMethod.releaseDate:
        result.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
        break;
      case SortMethod.releaseDateDesc:
        result.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case SortMethod.shuffle:
        result.shuffle();
        break;
      case SortMethod.manual:
        break;
    }
    
    return result;
  }

  void _showShareAndImportOptions(SearchProvider provider, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sharing & Importing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showScanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import via Link'),
              onTap: () {
                Navigator.pop(context);
                _showImportLinkDialog(provider);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Web Link (WhatsApp/SMS)'),
              onTap: () {
                Navigator.pop(context);
                final link = provider.getShareLinkForList(_selectedList);
                Share.share('Check out my $_selectedList on MediaVore: $link');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Show QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCodeDialog(provider, settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQRCodeImage() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/mediavore_qr_${_selectedList.replaceAll(' ', '_')}.png').create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles([XFile(file.path)], text: 'Scan this QR code to import my $_selectedList on MediaVore');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing QR code: $e')),
        );
      }
    }
  }

  void _showQRCodeDialog(SearchProvider provider, SettingsProvider settings) {
    final link = provider.getCustomSchemeShareLinkForList(_selectedList);
    // Respect CURRENT visible order and filters
    final visibleItems = _getFilteredAndSortedItems(_currentItems, settings);
    final previewPosters = visibleItems.where((i) => i.posterPath != null).take(3).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share $_selectedList'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedList, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: QrImageView(
                        data: link,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Colors.deepPurple,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Colors.black,
                        ),
                        embeddedImage: _croppedLogoBytes != null ? MemoryImage(_croppedLogoBytes!) : null,
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(70, 70), // Significant size due to cropping
                        ),
                      ),
                    ),
                    if (previewPosters.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: previewPosters.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: 'https://image.tmdb.org/t/p/w92${item.posterPath}',
                              width: 45,
                              height: 65,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('MediaVore List Share', style: TextStyle(color: Colors.deepPurple, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Scan this with another phone to import the list.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQRCodeImage,
            tooltip: 'Share QR Code Image',
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: const Text('Scan MediaVore List'),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;
                    if (code != null && (code.startsWith('mediavore://share') || code.startsWith('https://mediavore.app/share'))) {
                      Navigator.pop(context);
                      _handleScannedLink(code);
                      break;
                    }
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Point your camera at a MediaVore QR code'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleScannedLink(String link) {
    try {
      final uri = Uri.parse(link);
      final name = uri.queryParameters['name'];
      final itemsStr = uri.queryParameters['items'];
      
      if (name != null && itemsStr != null) {
        final items = itemsStr.split(',');
        _showImportConfirmationDialog(context.read<SearchProvider>(), name, items);
      }
    } catch (_) {}
  }

  void _showImportLinkDialog(SearchProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import via Link'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste the shared link here',
            labelText: 'Share Link',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              
              try {
                final uri = Uri.parse(url);
                final name = uri.queryParameters['name'];
                final itemsStr = uri.queryParameters['items'];
                
                if (name != null && itemsStr != null) {
                  final items = itemsStr.split(',');
                  Navigator.pop(context);
                  _showImportConfirmationDialog(provider, name, items);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid link format')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not parse link')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showImportConfirmationDialog(SearchProvider provider, String suggestedName, List<String> entries) {
    final controller = TextEditingController(text: suggestedName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to import a list with ${entries.length} items.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'List Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await provider.importList(controller.text, entries);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                   _selectedList = controller.text;
                });
                loadSavedMedia();
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showListPicker(context, provider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedList == 'watchlist' ? 'Watchlist' : _selectedList),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareAndImportOptions(provider, settings),
            tooltip: 'Sharing & Importing',
          ),
          PopupMenuButton<SortMethod>(
            icon: const Icon(Icons.sort),
            onSelected: (method) => setState(() => _sortMethod = method),
            itemBuilder: (context) => [
              const PopupMenuItem(value: SortMethod.manual, child: Text('Manual Order')),
              const PopupMenuItem(value: SortMethod.releaseDate, child: Text('Release Date (Oldest)')),
              const PopupMenuItem(value: SortMethod.releaseDateDesc, child: Text('Release Date (Newest)')),
              const PopupMenuItem(value: SortMethod.shuffle, child: Text('Shuffle')),
            ],
          ),
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () async {
              setState(() => _isRefreshing = true);
              await loadSavedMedia(forceRefresh: true);
              if (mounted) setState(() => _isRefreshing = false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage())),
          ),
        ],
      ),
      body: FutureBuilder<List<MediaItem>>(
        future: _savedMediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _savedMediaFuture != null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items in this list.'));
          }

          final sortedItems = _getFilteredAndSortedItems(snapshot.data!, settings);
          
          if (settings.displayMode == DisplayMode.grid) {
            return _buildGridView(sortedItems, provider, settings);
          } else if (settings.displayMode == DisplayMode.swipe) {
            return _buildSwipeView(sortedItems, provider);
          } else {
            return _buildListView(sortedItems, provider);
          }
        },
      ),
    );
  }

  Widget _buildListView(List<MediaItem> items, SearchProvider provider) {
    return ReorderableListView.builder(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) async {
        if (_sortMethod != SortMethod.manual) return; 

        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
        });
        
        _currentItems = items;
        
        final orderedEntries = items.map((e) => '${e.id}:${e.mediaType.name}').toList();
        await provider.updateListOrder(_selectedList, orderedEntries);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaListTile(
          key: ValueKey('${item.id}_${item.mediaType.name}'),
          item: item,
          provider: provider,
          onRemove: () => _removeItem(item),
        );
      },
    );
  }

  Widget _buildGridView(List<MediaItem> items, SearchProvider provider, SettingsProvider settings) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: settings.gridSize.round(),
        childAspectRatio: 0.66,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaGridItem(item: item, provider: provider, onRemove: () => _removeItem(item));
      },
    );
  }

  Widget _buildSwipeView(List<MediaItem> items, SearchProvider provider) {
    return PageView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaSwipeItem(item: item, provider: provider, onRemove: () => _removeItem(item));
      },
    );
  }

  void _showListPicker(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(padding: const EdgeInsets.all(16.0), child: Text('Switch List', style: Theme.of(context).textTheme.titleLarge)),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.listNames.length,
                  itemBuilder: (context, index) {
                    final name = provider.listNames[index];
                    final previews = provider.getPreviewsForList(name);
                    final count = provider.getListItemCount(name);
                    
                    return ListTile(
                      leading: _buildListPreviewIcon(previews, provider),
                      title: Text(name == 'watchlist' ? 'Watchlist' : name),
                      subtitle: Text('$count items'),
                      selected: name == _selectedList,
                      trailing: (name != 'watchlist') 
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteListConfirm(context, provider, name);
                            },
                          )
                        : null,
                      onTap: () {
                        setState(() { _selectedList = name; });
                        loadSavedMedia();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New List'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateListDialog(context, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListPreviewIcon(List<MediaItemPreview> previews, SearchProvider provider) {
    if (previews.isEmpty) {
      return Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.movie_outlined, size: 20));
    }
    if (previews.length == 1) {
       return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w92${previews[0].posterPath}', width: 40, height: 40, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.movie)),
      );
    }
    return SizedBox(
      width: 40, height: 40,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 1, mainAxisSpacing: 1),
        itemCount: 4,
        itemBuilder: (context, index) {
          if (index >= previews.length || previews[index].posterPath == null) return Container(color: Colors.grey[200]);
          return CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w92${previews[index].posterPath}', fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: Colors.grey));
        },
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, SearchProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'List name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.createList(controller.text);
                setState(() { _selectedList = controller.text; });
                loadSavedMedia();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteListConfirm(BuildContext context, SearchProvider provider, String listName) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "$listName"? This will also remove all items from this list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (_selectedList == listName) {
                setState(() { _selectedList = 'watchlist'; });
              }
              await provider.deleteList(listName);
              if (context.mounted) Navigator.pop(context);
              loadSavedMedia();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MediaListTile extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final VoidCallback onRemove;

  const _MediaListTile({super.key, required this.item, required this.provider, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isTv = item.mediaType == MediaType.tv;
    final isLiked = provider.isLiked(item);
    
    String lengthText = '';
    if (isTv) {
      lengthText = '${item.numberOfSeasons ?? "?"} seasons';
    } else if (item.runtime != null) {
      lengthText = '${item.runtime} min';
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item))),
      onLongPress: () => _showRemoveDialog(context),
      child: ListTile(
        leading: _PosterWithBadge(item: item, provider: provider),
        title: Row(
          children: [
            Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isLiked) const Icon(Icons.favorite, size: 16, color: Colors.red),
          ],
        ),
        subtitle: Text('${item.releaseDate} • $lengthText'),
        trailing: ReorderableDragStartListener(
          index: context.findAncestorStateOfType<SavedMediaPageState>()?._currentItems.indexOf(item) ?? 0,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from list?'),
        content: Text('Do you want to remove "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { onRemove(); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final VoidCallback onRemove;

  const _MediaGridItem({required this.item, required this.provider, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item))),
      onLongPress: () => _showRemoveDialog(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _PosterWithBadge(item: item, provider: provider, width: double.infinity, height: double.infinity),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { onRemove(); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _MediaSwipeItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final VoidCallback onRemove;

  const _MediaSwipeItem({required this.item, required this.provider, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item))),
        onLongPress: () => _showRemoveDialog(context),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _PosterWithBadge(item: item, provider: provider, width: double.infinity, height: double.infinity),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(item.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center, maxLines: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { onRemove(); Navigator.pop(context); }, child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _PosterWithBadge extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final double? width;
  final double? height;

  const _PosterWithBadge({required this.item, required this.provider, this.width = 50, this.height});

  @override
  Widget build(BuildContext context) {
    final seenCount = provider.getSeenCount(item);
    final isSeen = seenCount > 0;
    final isTv = item.mediaType == MediaType.tv;
    
    bool isFinished = false;
    if (isSeen) {
      if (isTv && item.numberOfEpisodes != null && item.numberOfEpisodes! > 0) {
        isFinished = seenCount >= item.numberOfEpisodes!;
      } else if (!isTv) {
        isFinished = true;
      }
    }

    return Stack(
      children: [
        if (item.posterPath != null)
          CachedNetworkImage(
            imageUrl: 'https://image.tmdb.org/t/p/w342${item.posterPath}',
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => Icon(isTv ? Icons.tv : Icons.movie, size: width),
          )
        else
          Container(
            width: width, height: height, color: Colors.grey[200],
            child: Icon(isTv ? Icons.tv : Icons.movie, size: width != null ? width! / 2 : 24),
          ),
        if (isSeen)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(color: isFinished ? Colors.blue : Colors.green, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: Icon(isFinished ? Icons.done_all : Icons.check, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
