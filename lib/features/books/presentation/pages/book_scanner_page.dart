import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/books/domain/entities/book.dart';
import 'package:mediavore/features/books/presentation/pages/book_detail_page.dart';
import 'package:mediavore/features/books/presentation/providers/book_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class BookScannerPage extends StatefulWidget {
  const BookScannerPage({super.key});

  @override
  State<BookScannerPage> createState() => _BookScannerPageState();
}

class _BookScannerPageState extends State<BookScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );
  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un livre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Scan overlay
          _buildScanOverlay(colors),
          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Recherche du livre...',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!),
                        ),
                        if (_lastScannedCode != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ISBN: $_lastScannedCode',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.comments,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 280,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(
                color: colors.logicFlow.withValues(alpha: 0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Placez le code-barres dans le cadre',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;

      // Validate ISBN format (EAN-13 for books starts with 978 or 979)
      if (!_isValidIsbn(code)) continue;

      setState(() {
        _isProcessing = true;
        _hasScanned = true;
        _lastScannedCode = code;
      });

      await _lookupBook(code);
      return;
    }
  }

  bool _isValidIsbn(String code) {
    // ISBN-13 (EAN-13 starting with 978 or 979)
    if (code.length == 13 && (code.startsWith('978') || code.startsWith('979'))) {
      return true;
    }
    // ISBN-10
    if (code.length == 10) {
      return true;
    }
    // Also accept any EAN-13 code
    if (code.length == 13 && RegExp(r'^\d{13}$').hasMatch(code)) {
      return true;
    }
    return false;
  }

  Future<void> _lookupBook(String isbn) async {
    final provider = context.read<BookProvider>();

    try {
      // Check if book already exists in library
      final existing = await provider.getBookByIsbn(isbn);
      if (existing != null && mounted) {
        setState(() => _isProcessing = false);
        _showBookFound(existing, alreadyInLibrary: true);
        return;
      }

      // Search remote
      final book = await provider.fetchBookByIsbn(isbn);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (book != null) {
        _showBookFound(book, alreadyInLibrary: false);
      } else {
        _showNotFound(isbn);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showNotFound(isbn);
      }
    }
  }

  void _showBookFound(Book book, {required bool alreadyInLibrary}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BookFoundSheet(
        book: book,
        alreadyInLibrary: alreadyInLibrary,
        onAdd: () async {
          final provider = context.read<BookProvider>();
          await provider.addBook(book);
          if (ctx.mounted) Navigator.pop(ctx);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${book.title} ajouté à la bibliothèque'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Allow scanning another book
            setState(() => _hasScanned = false);
          }
        },
        onViewDetail: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
          );
        },
        onScanAnother: () {
          Navigator.pop(ctx);
          setState(() => _hasScanned = false);
        },
      ),
    );
  }

  void _showNotFound(String isbn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Livre introuvable'),
        content: Text(
          'Aucun livre trouvé pour l\'ISBN: $isbn.\n\nVoulez-vous réessayer ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hasScanned = false);
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _BookFoundSheet extends StatelessWidget {
  final Book book;
  final bool alreadyInLibrary;
  final VoidCallback onAdd;
  final VoidCallback onViewDetail;
  final VoidCallback onScanAnother;

  const _BookFoundSheet({
    required this.book,
    required this.alreadyInLibrary,
    required this.onAdd,
    required this.onViewDetail,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.comments,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                alreadyInLibrary ? Icons.check_circle : Icons.menu_book,
                color: alreadyInLibrary ? colors.success : colors.logicFlow,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alreadyInLibrary ? 'Déjà dans la bibliothèque' : 'Livre trouvé !',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: alreadyInLibrary ? colors.success : Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            book.authorsDisplay,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          if (book.publisher != null || book.publishYear != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                book.publisher,
                if (book.publishYear != null) '${book.publishYear}',
              ].whereType<String>().join(' · '),
              style: TextStyle(fontSize: 13, color: colors.comments),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              if (!alreadyInLibrary) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetail,
                  child: const Text('Voir détails'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onScanAnother,
              child: const Text('Scanner un autre livre'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
