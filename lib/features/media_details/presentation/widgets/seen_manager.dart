import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

class SeenManager extends StatefulWidget {
  final MediaItem item;
  final int? seasonNumber;
  final int? episodeNumber;
  final bool compact;

  const SeenManager({
    super.key,
    required this.item,
    this.seasonNumber,
    this.episodeNumber,
    this.compact = false,
  });

  @override
  State<SeenManager> createState() => _SeenManagerState();
}

class _SeenManagerState extends State<SeenManager> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final colors = context.appColors;

    bool isSeen;
    int? count;

    if (widget.seasonNumber != null && widget.episodeNumber != null) {
      final history = provider.seenItems.where((s) =>
        s.tmdbId == widget.item.id &&
        s.type == widget.item.mediaType &&
        s.seasonNumber == widget.seasonNumber &&
        s.episodeNumber == widget.episodeNumber
      ).toList();
      isSeen = history.isNotEmpty;
      count = history.length;
    } else {
      count = provider.getSeenCount(widget.item);
      isSeen = count > 0;
    }

    final isTv = widget.item.mediaType == MediaType.tv;

    // Use a single smart button for compact/episode views to avoid duplication
    if (widget.compact || (widget.seasonNumber != null && widget.episodeNumber != null)) {
      return IconButton(
        icon: Icon(
          isSeen ? Icons.check_circle : Icons.check_circle_outline,
          color: isSeen ? colors.success : colors.comments,
        ),
        tooltip: isSeen ? 'View History' : 'Mark as seen',
        onPressed: () {
          if (isSeen) {
            _showSeenHistory(context, provider);
          } else {
            _markAsSeenWithFlow(context, provider);
          }
        },
      );
    }

    return ListTile(
      title: Text(isTv ? 'Episodes Seen' : 'Seen'),
      subtitle: Text(isTv ? '$count episodes' : (isSeen ? 'Yes' : 'No')),
      trailing: IconButton(
        icon: Icon(
          isSeen ? Icons.check_circle : Icons.check_circle_outline,
          color: isSeen ? colors.success : colors.comments,
        ),
        onPressed: () {
          if (isSeen) {
            _showSeenHistory(context, provider);
          } else {
            _markAsSeenWithFlow(context, provider);
          }
        },
      ),
      onLongPress: isSeen ? () => _confirmClear(context, provider) : null,
    );
  }

  Future<void> _markAsSeenWithFlow(BuildContext context, SearchProvider provider) async {
    final item = widget.item;
    final seasonNumber = widget.seasonNumber;
    final episodeNumber = widget.episodeNumber;

    final DateTime? finalDateTime = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => _SeenDateTimePickerDialog(
        item: item,
        initialDate: DateTime.now(),
      ),
    );

    if (finalDateTime != null) {
      await provider.markAsSeen(SeenItem(
        tmdbId: item.id,
        type: item.mediaType,
        title: item.title,
        posterPath: item.posterPath,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        seenDate: finalDateTime,
      ));
    }
  }

  void _confirmClear(BuildContext context, SearchProvider provider) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear History'),
        content: Text('Are you sure you want to clear all viewing history for "${widget.item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.removeFromSeen(widget.item.id, widget.item.mediaType);
              Navigator.pop(dialogContext);
            },
            child: Text('Clear All', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void _showSeenHistory(BuildContext context, SearchProvider provider) {
    final history = provider.seenItems.where((s) =>
      s.tmdbId == widget.item.id &&
      s.type == widget.item.mediaType &&
      s.seasonNumber == widget.seasonNumber &&
      s.episodeNumber == widget.episodeNumber
    ).toList();

    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Viewing History', style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: colors.success),
                title: const Text('Add New Viewing', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _markAsSeenWithFlow(context, provider);
                },
              ),
              const Divider(),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No viewing history found for this item.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final seenEntry = history[index];
                      return ListTile(
                        leading: Icon(Icons.event, color: colors.comments),
                        title: Text(DateFormat('MMM dd, yyyy - HH:mm').format(seenEntry.seenDate)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed: () {
                            provider.deleteSeenEntry(seenEntry.id!);
                            if (history.length <= 1) Navigator.pop(sheetContext);
                          },
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _confirmClear(context, provider);
                  },
                  child: const Text('Remove All History'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeenDateTimePickerDialog extends StatefulWidget {
  final MediaItem item;
  final DateTime initialDate;

  const _SeenDateTimePickerDialog({
    required this.item,
    required this.initialDate,
  });

  @override
  State<_SeenDateTimePickerDialog> createState() => _SeenDateTimePickerDialogState();
}

class _SeenDateTimePickerDialogState extends State<_SeenDateTimePickerDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isTextEntry = false;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDate);
    _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(_selectedDate));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isMovie = widget.item.mediaType == MediaType.movie;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(isMovie ? Icons.movie : Icons.tv, color: colors.logicFlow, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark as seen',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.comments),
                        ),
                        Text(
                          widget.item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isTextEntry ? Icons.calendar_month : Icons.keyboard),
                    onPressed: () => setState(() => _isTextEntry = !_isTextEntry),
                    tooltip: _isTextEntry ? 'Use Calendar' : 'Type Date',
                    color: colors.logicFlow,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isTextEntry)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().add(const Duration(minutes: 1)),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
                      });
                    },
                  ),
                )
              else
                TextField(
                  controller: _dateController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Date (DD/MM/YYYY)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.event),
                    hintText: '31/12/2023',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [DateTextFormatter()],
                  onChanged: (val) {
                    try {
                      final parsed = DateFormat('dd/MM/yyyy').parseStrict(val);
                      setState(() {
                        _selectedDate = parsed;
                      });
                    } catch (_) {}
                  },
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.logicFlow.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: colors.logicFlow),
                      const SizedBox(width: 12),
                      Text(
                        'Time: ${DateFormat('HH:mm').format(DateTime(0, 0, 0, _selectedTime.hour, _selectedTime.minute))}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.logicFlow,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      try {
                        if (_isTextEntry) {
                          _selectedDate = DateFormat('dd/MM/yyyy').parseStrict(_dateController.text);
                        }

                        final result = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        Navigator.pop(context, result);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid date (DD/MM/YYYY)')),
                        );
                      }
                    },
                    child: const Text('LOG VIEWING'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
