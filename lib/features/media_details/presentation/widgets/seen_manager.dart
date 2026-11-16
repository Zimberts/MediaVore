import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/formatters.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Opens the date and time picker dialog for a viewing.
/// Returns the chosen [DateTime], or `null` if cancelled.
Future<DateTime?> showSeenDateTimePickerDialog(
  BuildContext context, {
  required MediaItem item,
  required DateTime initialDate,
  bool isEditing = false,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => _SeenDateTimePickerDialog(
      item: item,
      initialDate: initialDate,
      isEditing: isEditing,
    ),
  );
}

class SeenManager extends StatefulWidget {
  final MediaItem item;
  final int? seasonNumber;
  final int? episodeNumber;
  final bool compact;

  /// Full-width main action of the detail page: "Mark as seen", then
  /// "Rewatch" (or "Rewatch…" in advanced mode) once the title has been seen.
  final bool primary;

  const SeenManager({
    super.key,
    required this.item,
    this.seasonNumber,
    this.episodeNumber,
    this.compact = false,
    this.primary = false,
  });

  @override
  State<SeenManager> createState() => _SeenManagerState();
}

class _SeenManagerState extends State<SeenManager> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final settings = Provider.of<SettingsProvider?>(context);
    final advanced = settings?.advancedTracking ?? false;
    final colors = context.appColors;

    bool isSeen;
    int? count;

    if (widget.seasonNumber != null && widget.episodeNumber != null) {
      final history = provider.seenItems
          .where(
            (s) =>
                s.tmdbId == widget.item.id &&
                s.type == widget.item.mediaType &&
                s.seasonNumber == widget.seasonNumber &&
                s.episodeNumber == widget.episodeNumber,
          )
          .toList();
      isSeen = history.isNotEmpty;
      count = history.length;
    } else {
      count = provider.getSeenCount(widget.item);
      isSeen = count > 0;
    }

    final isTv = widget.item.mediaType == MediaType.tv;

    if (widget.primary) {
      final String label;
      if (!isSeen) {
        label = advanced
            ? context.l10n.commonMarkAsSeenWithDots
            : context.l10n.commonMarkAsSeen;
      } else {
        label = advanced
            ? context.l10n.seenRewatchActionWithDots
            : context.l10n.seenRewatchAction;
      }

      return Tooltip(
        message: label,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: () {
            if (!advanced) {
              _markAsSeenImmediate(context, provider);
            } else {
              _markAsSeenWithFlow(context, provider);
            }
          },
          icon: isSeen ? const Icon(Icons.check, size: 18) : null,
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    // Use a single smart button for compact/episode views to avoid duplication
    if (widget.compact ||
        (widget.seasonNumber != null && widget.episodeNumber != null)) {
      final String tooltip;
      if (!isSeen) {
        tooltip = advanced
            ? context.l10n.commonMarkAsSeenWithDots
            : context.l10n.commonMarkAsSeen;
      } else {
        tooltip = advanced
            ? context.l10n.seenVisionnagesSectionTitle
            : context.l10n.seenRewatchAction;
      }

      return IconButton(
        icon: Icon(
          isSeen ? Icons.check_circle : Icons.check_circle_outline,
          color: isSeen ? colors.success : colors.text2,
        ),
        tooltip: tooltip,
        onPressed: () {
          if (!advanced) {
            _markAsSeenImmediate(context, provider);
          } else {
            if (isSeen) {
              _showSeenHistory(context, provider);
            } else {
              _markAsSeenWithFlow(context, provider);
            }
          }
        },
        onLongPress: isSeen ? () => _confirmClear(context, provider) : null,
      );
    }

    return ListTile(
      title: Text(
        isTv ? context.l10n.seenEpisodesSeenTitle : context.l10n.seenSeen,
      ),
      subtitle: Text(
        isTv
            ? context.l10n.seenEpisodeCount(count)
            : (isSeen ? context.l10n.commonYes : context.l10n.commonNo),
      ),
      trailing: IconButton(
        icon: Icon(
          isSeen ? Icons.check_circle : Icons.check_circle_outline,
          color: isSeen ? colors.success : colors.text2,
        ),
        tooltip: isSeen
            ? (advanced
                ? context.l10n.seenVisionnagesSectionTitle
                : context.l10n.seenRewatchAction)
            : (advanced
                ? context.l10n.commonMarkAsSeenWithDots
                : context.l10n.commonMarkAsSeen),
        onPressed: () {
          if (!advanced) {
            _markAsSeenImmediate(context, provider);
          } else {
            if (isSeen) {
              _showSeenHistory(context, provider);
            } else {
              _markAsSeenWithFlow(context, provider);
            }
          }
        },
      ),
      onLongPress: isSeen ? () => _confirmClear(context, provider) : null,
    );
  }

  Future<void> _markAsSeenImmediate(
    BuildContext context,
    SearchProvider provider,
  ) async {
    final item = widget.item;
    final l10n = context.l10n;
    final undo = await provider.markItemSeen(
      SeenItem(
        tmdbId: item.id,
        type: item.mediaType,
        title: item.title,
        posterPath: item.posterPath,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
        seenDate: DateTime.now(),
      ),
    );

    showAppMessage(
      l10n.seenAddedMessage(item.title),
      actionLabel: l10n.commonUndo,
      onAction: undo,
    );
  }

  Future<void> _markAsSeenWithFlow(
    BuildContext context,
    SearchProvider provider,
  ) async {
    final item = widget.item;
    final seasonNumber = widget.seasonNumber;
    final episodeNumber = widget.episodeNumber;

    final DateTime? finalDateTime = await showSeenDateTimePickerDialog(
      context,
      item: item,
      initialDate: DateTime.now(),
    );

    if (finalDateTime != null) {
      await provider.markAsSeen(
        SeenItem(
          tmdbId: item.id,
          type: item.mediaType,
          title: item.title,
          posterPath: item.posterPath,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
          seenDate: finalDateTime,
        ),
      );
    }
  }

  Future<void> _confirmClear(
    BuildContext context,
    SearchProvider provider,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: context.l10n.seenClearHistory,
      message: context.l10n.seenClearHistoryMessage(widget.item.title),
      actions: [
        AppDialogAction(
          label: context.l10n.commonCancel,
          value: false,
        ),
        AppDialogAction(
          label: context.l10n.seenClearAll,
          value: true,
          danger: true,
        ),
      ],
    );

    if (confirmed == true) {
      if (widget.seasonNumber != null && widget.episodeNumber != null) {
        final history = provider.seenItems
            .where(
              (s) =>
                  s.tmdbId == widget.item.id &&
                  s.type == widget.item.mediaType &&
                  s.seasonNumber == widget.seasonNumber &&
                  s.episodeNumber == widget.episodeNumber,
            )
            .toList();
        for (final entry in history) {
          if (entry.id != null) {
            await provider.deleteSeenEntry(entry.id!);
          }
        }
      } else {
        await provider.removeFromSeen(widget.item.id, widget.item.mediaType);
      }
    }
  }

  void _showSeenHistory(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EpisodeSeenHistorySheet(
        item: widget.item,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
        onClearRequested: () => _confirmClear(context, provider),
      ),
    );
  }
}

class _EpisodeSeenHistorySheet extends StatelessWidget {
  final MediaItem item;
  final int? seasonNumber;
  final int? episodeNumber;
  final VoidCallback onClearRequested;

  const _EpisodeSeenHistorySheet({
    required this.item,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.onClearRequested,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final colors = context.appColors;
    final l10n = context.l10n;

    final history = provider.seenItems
        .where(
          (s) =>
              s.tmdbId == item.id &&
              s.type == item.mediaType &&
              s.seasonNumber == seasonNumber &&
              s.episodeNumber == episodeNumber,
        )
        .toList();

    history.sort((a, b) => a.seenDate.compareTo(b.seenDate));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.seenVisionnagesSectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: colors.success),
              title: Text(
                l10n.seenAddViewing,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final date = await showSeenDateTimePickerDialog(
                  context,
                  item: item,
                  initialDate: DateTime.now(),
                );
                if (date != null) {
                  await provider.markAsSeen(
                    SeenItem(
                      tmdbId: item.id,
                      type: item.mediaType,
                      title: item.title,
                      posterPath: item.posterPath,
                      seasonNumber: seasonNumber,
                      episodeNumber: episodeNumber,
                      seenDate: date,
                    ),
                  );
                }
              },
            ),
            const Divider(),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(l10n.seenNoHistory),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final seenEntry = history[index];
                    final ordinal = l10n.seenOrdinal((index + 1).toString());
                    final dateStr = Formatters.formatSeenDateTime(
                      seenEntry.seenDate,
                      l10n.localeName,
                    );

                    return ListTile(
                      leading: Icon(Icons.history, color: colors.primary),
                      title: Text('$ordinal · $dateStr'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: l10n.seenEditViewing,
                            onPressed: () async {
                              final newDate = await showSeenDateTimePickerDialog(
                                context,
                                item: item,
                                initialDate: seenEntry.seenDate,
                                isEditing: true,
                              );
                              if (newDate != null) {
                                await provider.updateSeenEntry(
                                  seenEntry.copyWith(seenDate: newDate),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: colors.error),
                            tooltip: l10n.commonDelete,
                            onPressed: () async {
                              final confirmed = await showAppDialog<bool>(
                                context: context,
                                title: l10n.seenRemoveLogTitle,
                                message: l10n.seenRemoveLogMessage,
                                actions: [
                                  AppDialogAction(
                                    label: l10n.commonCancel,
                                    value: false,
                                  ),
                                  AppDialogAction(
                                    label: l10n.commonDelete,
                                    value: true,
                                    danger: true,
                                  ),
                                ],
                              );
                              if (confirmed == true && seenEntry.id != null) {
                                await provider.deleteSeenEntry(seenEntry.id!);
                                if (history.length <= 1 && context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ],
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
                  Navigator.pop(context);
                  onClearRequested();
                },
                child: Text(l10n.seenRemoveAllHistory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeenDateTimePickerDialog extends StatefulWidget {
  final MediaItem item;
  final DateTime initialDate;
  final bool isEditing;

  const _SeenDateTimePickerDialog({
    required this.item,
    required this.initialDate,
    this.isEditing = false,
  });

  @override
  State<_SeenDateTimePickerDialog> createState() =>
      _SeenDateTimePickerDialogState();
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
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
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
    final l10n = context.l10n;

    final title = widget.isEditing
        ? l10n.seenEditViewing
        : l10n.commonMarkAsSeen;
    final buttonLabel = widget.isEditing
        ? l10n.commonSave
        : l10n.seenLogViewing;

    final now = DateTime.now();
    final calendarInitialDate =
        _selectedDate.isAfter(now) ? now : _selectedDate;

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
                  Icon(
                    isMovie ? Icons.movie : Icons.tv,
                    color: colors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: colors.text2),
                        ),
                        Text(
                          widget.item.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTextEntry ? Icons.calendar_month : Icons.keyboard,
                    ),
                    onPressed: () =>
                        setState(() => _isTextEntry = !_isTextEntry),
                    tooltip: _isTextEntry
                        ? l10n.seenUseCalendar
                        : l10n.seenTypeDate,
                    color: colors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isTextEntry)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CalendarDatePicker(
                    initialDate: calendarInitialDate,
                    firstDate: DateTime(1900),
                    lastDate: now,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                        _dateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(date);
                      });
                    },
                  ),
                )
              else
                TextField(
                  controller: _dateController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.seenDateLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    } catch (_) {
                      // Intentionally ignored: partial/invalid date while typing.
                    }
                  },
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: colors.primary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.seenTimeLabel(
                          DateFormat('HH:mm').format(
                            DateTime(
                              0,
                              0,
                              0,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                    child: Text(l10n.seenCancelCaps),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      try {
                        if (_isTextEntry) {
                          _selectedDate = DateFormat(
                            'dd/MM/yyyy',
                          ).parseStrict(_dateController.text);
                        }

                        final result = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );

                        if (result.isAfter(DateTime.now())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.seenFutureDateError),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context, result);
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.seenInvalidDate)),
                        );
                      }
                    },
                    child: Text(buttonLabel),
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
