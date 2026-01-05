import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SeenManager extends StatefulWidget {
  final int tmdbId;
  final MediaType type;
  final String title;
  final String? posterPath;
  final int? seasonNumber;
  final int? episodeNumber;
  final VoidCallback? onSeenChanged;

  const SeenManager({
    super.key,
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
    this.seasonNumber,
    this.episodeNumber,
    this.onSeenChanged,
  });

  @override
  State<SeenManager> createState() => _SeenManagerState();
}

class _SeenManagerState extends State<SeenManager> {
  List<SeenItem> _viewings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSeenStatus();
  }

  Future<void> _checkSeenStatus() async {
    final provider = context.read<SearchProvider>();
    final allEntries = await provider.loadSeenStatusForItem(widget.tmdbId, widget.type);
    
    if (mounted) {
      setState(() {
        _viewings = allEntries.where((s) => 
          s.seasonNumber == widget.seasonNumber && 
          s.episodeNumber == widget.episodeNumber
        ).toList();
        _viewings.sort((a, b) => b.seenDate.compareTo(a.seenDate));
        _isLoading = false;
      });
    }
  }

  Future<void> _addViewing() async {
    final provider = context.read<SearchProvider>();
    
    if (!context.mounted) return;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'When did you see this?',
    );

    if (pickedDate != null) {
      await provider.markAsSeen(SeenItem(
        tmdbId: widget.tmdbId,
        type: widget.type,
        title: widget.title,
        posterPath: widget.posterPath,
        seenDate: pickedDate,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      ));
      
      await _checkSeenStatus();
      widget.onSeenChanged?.call();
    }
  }

  Future<bool?> _confirmDeletion({required bool all}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(all ? 'Remove all logs?' : 'Remove log?'),
        content: Text(all 
          ? 'Are you sure you want to remove all viewing history for this item?' 
          : 'Are you sure you want to remove this specific viewing entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeViewing(int id) async {
    final provider = context.read<SearchProvider>();
    await provider.deleteSeenEntry(id);
    await _checkSeenStatus();
    widget.onSeenChanged?.call();
  }

  Future<void> _removeAll() async {
    final provider = context.read<SearchProvider>();
    await provider.removeFromSeen(
      widget.tmdbId,
      widget.type,
      seasonNumber: widget.seasonNumber,
      episodeNumber: widget.episodeNumber,
    );
    await _checkSeenStatus();
    widget.onSeenChanged?.call();
  }

  void _showViewingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Viewings: ${widget.title}${widget.seasonNumber != null ? " (S${widget.seasonNumber} E${widget.episodeNumber})" : ""}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                    title: const Text('Add another viewing'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _addViewing();
                    },
                  ),
                  if (_viewings.isNotEmpty) ...[
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _viewings.length,
                        itemBuilder: (context, index) {
                          final viewing = _viewings[index];
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(DateFormat.yMMMMd().format(viewing.seenDate)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _confirmDeletion(all: false);
                                if (confirm == true) {
                                  await _removeViewing(viewing.id!);
                                  setModalState(() {
                                    _viewings.removeAt(index);
                                  });
                                  if (_viewings.isEmpty) {
                                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Remove all viewings'),
                      onTap: () async {
                        final confirm = await _confirmDeletion(all: true);
                        if (confirm == true) {
                          await _removeAll();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));

    final isSeen = _viewings.isNotEmpty;

    return IconButton(
      icon: Stack(
        children: [
          Icon(
            isSeen ? Icons.visibility : Icons.visibility_off,
            color: isSeen ? Theme.of(context).primaryColor : Colors.grey,
          ),
          if (_viewings.length > 1)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  '${_viewings.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: isSeen ? _showViewingsSheet : _addViewing,
      tooltip: isSeen ? 'Manage viewings' : 'Mark as seen',
    );
  }
}
