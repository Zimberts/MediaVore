import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mediavore/core/di/injection.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/presentation/pages/media_detail_page.dart';
import 'package:mediavore/features/media_details/presentation/widgets/like_button.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/pages/settings_page.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class SavedMediaPage extends StatefulWidget {
  const SavedMediaPage({super.key});

  @override
  State<SavedMediaPage> createState() => SavedMediaPageState();
}

enum SortMethod { manual, releaseDate, shuffle }

class SavedMediaPageState extends State<SavedMediaPage> {
  late final MediaRepository _mediaRepository;
  String _selectedList = 'watchlist';
  Future<List<MediaItem>>? _savedMediaFuture;
  bool _isRefreshing = false;
  SortMethod _sortMethod = SortMethod.manual;
  bool _isReversed = false;
  List<MediaItem> _currentItems = [];
  final GlobalKey _qrKey = GlobalKey();
  Uint8List? _croppedLogoBytes;

  // Edit Mode State
  bool _isEditMode = false;
  final Set<String> _selectedItems = {};

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
        _isEditMode = false;
        _selectedItems.clear();
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

  Future<void> _removeSelectedItems() async {
    final provider = context.read<SearchProvider>();
    final itemsToRemove = _currentItems.where((item) => _selectedItems.contains('${item.id}:${item.mediaType.name}')).toList();

    for (final item in itemsToRemove) {
      await provider.toggleInList(item, _selectedList);
    }

    setState(() {
      _isEditMode = false;
      _selectedItems.clear();
    });
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
      case SortMethod.shuffle:
        result.shuffle();
        break;
      case SortMethod.manual:
        break;
    }

    if (_isReversed) {
      result = result.reversed.toList();
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
    final colors = context.appColors;

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
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: colors.logicFlow,
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
                              placeholder: (context, url) => Container(color: colors.placeholder),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('MediaVore List Share', style: TextStyle(color: colors.logicFlow, fontSize: 14, fontWeight: FontWeight.w500)),
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
              final navigator = Navigator.of(context);
              await provider.importList(controller.text, entries);
              if (mounted) {
                navigator.pop();
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

  void _showSortOptions() {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.placeholder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text('Sort Options', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildSortItem(SortMethod.manual, 'Manual Order', Icons.drag_indicator, 'Drag and drop items to reorder'),
                  _buildSortItem(SortMethod.releaseDate, 'Release Date', Icons.calendar_today, 'Sort by when it was released'),
                  _buildSortItem(SortMethod.shuffle, 'Shuffle', Icons.shuffle, 'Randomize the list'),
                  const Divider(),
                  ListTile(
                    leading: Icon(_isReversed ? Icons.swap_vert_circle : Icons.swap_vert, color: _isReversed ? colors.logicFlow : null),
                    title: const Text('Reverse Order'),
                    trailing: Switch(
                      value: _isReversed,
                      activeThumbColor: colors.logicFlow,
                      onChanged: (value) {
                        setState(() {
                          _isReversed = value;
                        });
                        setSheetState(() {});
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _isReversed = !_isReversed;
                      });
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortItem(SortMethod method, String label, IconData icon, String subtitle) {
    final isSelected = _sortMethod == method;
    final colors = context.appColors;
    return ListTile(
      leading: Icon(icon, color: isSelected ? colors.logicFlow : null),
      title: Text(label, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.logicFlow : null,
      )),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected ? Icon(Icons.check_circle, color: colors.logicFlow) : null,
      onTap: () {
        setState(() {
          _sortMethod = method;
        });
        Navigator.pop(context);
      },
    );
  }

  void _toggleItemSelection(MediaItem item) {
    final key = '${item.id}:${item.mediaType.name}';
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
        if (_selectedItems.isEmpty) _isEditMode = false;
      } else {
        _selectedItems.add(key);
        _isEditMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final colors = context.appColors;

    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isEditMode) {
          setState(() {
            _isEditMode = false;
            _selectedItems.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isEditMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isEditMode = false; _selectedItems.clear(); }))
            : null,
          title: GestureDetector(
            onTap: _isEditMode ? null : () => _showListPicker(context, provider),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isEditMode ? '${_selectedItems.length} selected' : (_selectedList == 'watchlist' ? 'Watchlist' : _selectedList)),
                if (!_isEditMode) const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          actions: _isEditMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete, color: colors.error),
                  onPressed: _selectedItems.isEmpty ? null : _removeSelectedItems,
                  tooltip: 'Remove selected',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showShareAndImportOptions(provider, settings),
                  tooltip: 'Sharing & Importing',
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                  tooltip: 'Sort Options',
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
              return _buildListView(sortedItems, provider, settings);
            }
          },
        ),
      ),
    );
  }

  Widget _buildListView(List<MediaItem> items, SearchProvider provider, SettingsProvider settings) {
    return ReorderableListView.builder(
      itemCount: items.length,
      clipBehavior: Clip.none,
      onReorder: (oldIndex, newIndex) async {
        if (_sortMethod != SortMethod.manual) return;

        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);

          // Map indices to _currentItems to handle filtering correctly
          final oldPersistentIndex = _currentItems.indexOf(item);
          _currentItems.removeAt(oldPersistentIndex);

          if (newIndex < items.length - 1) {
             final nextItemInFiltered = items[newIndex + 1];
             final nextPersistentIndex = _currentItems.indexOf(nextItemInFiltered);
             _currentItems.insert(nextPersistentIndex, item);
          } else {
             _currentItems.add(item);
          }
        });

        final orderedEntries = _currentItems.map((e) => '${e.id}:${e.mediaType.name}').toList();
        await provider.updateListOrder(_selectedList, orderedEntries);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItems.contains('${item.id}:${item.mediaType.name}');

        return _MediaListTile(
          key: ValueKey('${item.id}_${item.mediaType.name}'),
          index: index,
          item: item,
          provider: provider,
          settings: settings,
          isEditMode: _isEditMode,
          isSelected: isSelected,
          onTap: () {
            if (_isEditMode) {
              _toggleItemSelection(item);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item)));
            }
          },
          onLongPress: () {
            if (!_isEditMode) {
              setState(() {
                _isEditMode = true;
                _selectedItems.add('${item.id}:${item.mediaType.name}');
              });
            }
          },
        );
      },
    );
  }

  Widget _buildGridView(List<MediaItem> items, SearchProvider provider, SettingsProvider settings) {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(8),
      clipBehavior: Clip.none,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: settings.gridSize.round(),
        childAspectRatio: 0.66,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) async {
        if (_sortMethod != SortMethod.manual) return;

        setState(() {
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);

          // Map indices to _currentItems to handle filtering correctly
          final oldPersistentIndex = _currentItems.indexOf(item);
          _currentItems.removeAt(oldPersistentIndex);

          if (newIndex < items.length - 1) {
             final nextItemInFiltered = items[newIndex + 1];
             final nextPersistentIndex = _currentItems.indexOf(nextItemInFiltered);
             _currentItems.insert(nextPersistentIndex, item);
          } else {
             _currentItems.add(item);
          }
        });

        final orderedEntries = _currentItems.map((e) => '${e.id}:${e.mediaType.name}').toList();
        await provider.updateListOrder(_selectedList, orderedEntries);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItems.contains('${item.id}:${item.mediaType.name}');

        return ReorderableDelayedDragStartListener(
          key: ValueKey('${item.id}_${item.mediaType.name}'),
          index: index,
          child: _MediaGridItem(
            item: item,
            provider: provider,
            isSelected: isSelected,
            isEditMode: _isEditMode,
            onTap: () {
              if (_isEditMode) {
                _toggleItemSelection(item);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item)));
              }
            },
            onLongPress: _isEditMode ? null : () {
              setState(() {
                _isEditMode = true;
                _selectedItems.add('${item.id}:${item.mediaType.name}');
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSwipeView(List<MediaItem> items, SearchProvider provider) {
    return PageView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaSwipeItem(item: item, provider: provider);
      },
    );
  }

  void _showListPicker(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final colors = context.appColors;
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
                            icon: Icon(Icons.delete_outline, color: colors.error),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteListConfirm(context, provider, name);
                            },
                          )
                        : null,
                      onTap: () {
                        setState(() { _selectedList = name; _isEditMode = false; _selectedItems.clear(); });
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
    final colors = context.appColors;
    if (previews.isEmpty) {
      return Container(width: 40, height: 40, decoration: BoxDecoration(color: colors.placeholder, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.movie_outlined, size: 20));
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
          if (index >= previews.length || previews[index].posterPath == null) return Container(color: colors.placeholder);
          return CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w92${previews[index].posterPath}', fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: colors.placeholder));
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
                setState(() { _selectedList = controller.text; _isEditMode = false; _selectedItems.clear(); });
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
     final colors = context.appColors;
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
                setState(() { _selectedList = 'watchlist'; _isEditMode = false; _selectedItems.clear(); });
              }
              await provider.deleteList(listName);
              if (context.mounted) Navigator.pop(context);
              loadSavedMedia();
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}

class _MediaListTile extends StatelessWidget {
  final MediaItem item;
  final int index;
  final SearchProvider provider;
  final SettingsProvider settings;
  final bool isEditMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MediaListTile({
    super.key,
    required this.index,
    required this.item,
    required this.provider,
    required this.settings,
    required this.isEditMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

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

    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected ? colors.logicFlow.withValues(alpha: 0.1) : null,
        child: ListTile(
          leading: _PosterWithBadge(item: item, provider: provider),
          title: Row(
            children: [
              Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isLiked) Icon(Icons.favorite, size: 16, color: colors.likeHeart),
            ],
          ),
          subtitle: Text('${item.releaseDate} • $lengthText'),
          trailing: isEditMode
            ? Checkbox(value: isSelected, onChanged: (_) => onTap())
            : ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
        ),
      ),
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final bool isSelected;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _MediaGridItem({
    required this.item,
    required this.provider,
    required this.isSelected,
    required this.isEditMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _PosterWithBadge(item: item, provider: provider, width: double.infinity, height: double.infinity, showBadge: false),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.logicFlow, width: 3),
                ),
              ),
            ),
          _PosterBadgeOnly(item: item, provider: provider),
          if (isEditMode)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                padding: const EdgeInsets.all(1),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? colors.logicFlow : colors.placeholder,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaSwipeItem extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;

  const _MediaSwipeItem({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _PosterWithBadge(item: item, provider: provider, width: double.infinity, height: double.infinity),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const SizedBox(width: 56), // Balances the larger LikeButton
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailPage(item: item))),
                      child: Text(item.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center, maxLines: 2),
                    ),
                  ),
                  LikeButton(item: item, iconSize: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterWithBadge extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;
  final double? width;
  final double? height;
  final bool showBadge;

  const _PosterWithBadge({required this.item, required this.provider, this.width = 50, this.height, this.showBadge = true});

  @override
  Widget build(BuildContext context) {
    final seenCount = provider.getSeenCount(item);
    final isSeen = seenCount > 0;
    final isTv = item.mediaType == MediaType.tv;
    final colors = context.appColors;

      return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.posterPath != null
            ? CachedNetworkImage(
                imageUrl: 'https://image.tmdb.org/t/p/w342${item.posterPath}',
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) => Icon(isTv ? Icons.tv : Icons.movie, size: width),
              )
            : Container(
                width: width, height: height, color: colors.placeholder,
                child: Icon(isTv ? Icons.tv : Icons.movie, size: width != null ? width! / 2 : 24),
              ),
        ),
        if (isSeen && showBadge)
          _PosterBadgeOnly(item: item, provider: provider),
      ],
    );
  }
}

// Extract the badge into its own widget
class _PosterBadgeOnly extends StatelessWidget {
  final MediaItem item;
  final SearchProvider provider;

  const _PosterBadgeOnly({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    final seenCount = provider.getSeenCount(item);
    if (seenCount <= 0) return const SizedBox.shrink();

    final isTv = item.mediaType == MediaType.tv;
    bool isFinished = isTv && item.numberOfEpisodes != null
        ? seenCount >= item.numberOfEpisodes!
        : !isTv;

    final colors = context.appColors;

    return Positioned(
      right: -4,
      bottom: -4,
      child: Container(
        decoration: BoxDecoration(
          color: isFinished ? colors.badgeBgSeen : colors.badgeBg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        padding: const EdgeInsets.all(2),
        child: Icon(
          isFinished ? Icons.done_all : Icons.check,
          size: 10,
          color: colors.badgeText,
        ),
      ),
    );
  }
}
