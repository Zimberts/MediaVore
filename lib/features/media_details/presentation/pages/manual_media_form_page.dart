import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/manual_media.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/poster_image_provider.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// General page for adding or editing a manual media item absent from TMDB.
class ManualMediaFormPage extends StatefulWidget {
  const ManualMediaFormPage({
    super.key,
    this.initialMedia,
    this.initialTitle,
    this.onPickImage,
  });

  final ManualMedia? initialMedia;
  final String? initialTitle;

  /// Optional override for picking an image path (used in widget tests).
  final Future<String?> Function()? onPickImage;

  @visibleForTesting
  static const Key titleFieldKey = Key('manual_media_title_field');
  @visibleForTesting
  static const Key runtimeFieldKey = Key('manual_media_runtime_field');
  @visibleForTesting
  static const Key sourceUrlFieldKey = Key('manual_media_source_url_field');
  @visibleForTesting
  static const Key saveButtonKey = Key('manual_media_save_button');
  @visibleForTesting
  static const Key addSeasonButtonKey = Key('manual_media_add_season_button');
  @visibleForTesting
  static const Key fillFromZoneKey = Key('manual_media_fill_from_zone');

  @override
  State<ManualMediaFormPage> createState() => _ManualMediaFormPageState();
}

class _ManualMediaFormPageState extends State<ManualMediaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late ManualMediaKind _kind;
  late final TextEditingController _titleController;
  late final TextEditingController _originalTitleController;
  late final TextEditingController _overviewController;
  late final TextEditingController _releaseDateController;
  late final TextEditingController _runtimeController;
  late final TextEditingController _posterUrlController;
  late final TextEditingController _genresController;
  late final TextEditingController _countriesController;
  late final TextEditingController _sourceUrlController;
  final List<TextEditingController> _seasonControllers = [];
  String? _localPosterPath;
  bool _isSaving = false;

  bool get _isEditing => widget.initialMedia != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initialMedia;
    _kind = m?.kind ?? ManualMediaKind.movie;
    _titleController = TextEditingController(
      text: m?.title ?? widget.initialTitle ?? '',
    );
    _originalTitleController = TextEditingController(
      text: m?.originalTitle ?? '',
    );
    _overviewController = TextEditingController(text: m?.overview ?? '');
    _releaseDateController = TextEditingController(text: m?.releaseDate ?? '');
    _runtimeController = TextEditingController(
      text: m?.runtime != null ? '${m!.runtime}' : '',
    );
    final initialPoster = m?.posterPath;
    if (TmdbImageUtils.isLocalPath(initialPoster)) {
      _localPosterPath = initialPoster;
      _posterUrlController = TextEditingController();
    } else {
      _posterUrlController = TextEditingController(text: initialPoster ?? '');
    }
    _genresController = TextEditingController(
      text: m?.genres?.join(', ') ?? '',
    );
    _countriesController = TextEditingController(
      text: m?.originCountries?.join(', ') ?? '',
    );
    _sourceUrlController = TextEditingController(text: m?.sourceUrl ?? '');

    final initialSeasons = m?.seasons;
    if (initialSeasons != null && initialSeasons.isNotEmpty) {
      for (final count in initialSeasons) {
        _seasonControllers.add(TextEditingController(text: '$count'));
      }
    } else {
      _seasonControllers.add(TextEditingController(text: '10'));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originalTitleController.dispose();
    _overviewController.dispose();
    _releaseDateController.dispose();
    _runtimeController.dispose();
    _posterUrlController.dispose();
    _genresController.dispose();
    _countriesController.dispose();
    _sourceUrlController.dispose();
    for (final c in _seasonControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  List<String>? _splitCommaList(TextEditingController controller) {
    final items = controller.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  }

  Future<void> _pickImage() async {
    String? pickedPath;
    if (widget.onPickImage != null) {
      pickedPath = await widget.onPickImage!();
    } else {
      final result = await FilePicker.pickFiles(type: FileType.image);
      pickedPath = result.firstOrNull?.path;
    }
    if (pickedPath == null || !mounted) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final postersDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}manual_posters',
      );
      if (!await postersDir.exists()) {
        await postersDir.create(recursive: true);
      }
      final fileName = pickedPath.split(RegExp(r'[/\\]')).last;
      final dotIndex = fileName.lastIndexOf('.');
      final ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';
      final destPath =
          '${postersDir.path}${Platform.pathSeparator}poster_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(pickedPath).copy(destPath);
      pickedPath = destPath;
    } catch (_) {
      // Fallback to original path if copying fails (e.g. in unit/widget tests).
    }

    if (!mounted) return;
    setState(() {
      _localPosterPath = pickedPath;
      _posterUrlController.clear();
    });
  }

  void _clearImage() {
    setState(() {
      _localPosterPath = null;
      _posterUrlController.clear();
    });
  }

  void _addSeason() {
    setState(() {
      _seasonControllers.add(TextEditingController(text: '10'));
    });
  }

  void _removeSeason(int index) {
    if (_seasonControllers.length <= 1) return;
    setState(() {
      final removed = _seasonControllers.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<SearchProvider>();
      final runtimeText = _trimmedOrNull(_runtimeController);
      final runtime = runtimeText == null ? null : int.tryParse(runtimeText);
      final seasons = _kind.isSeries
          ? [
              for (final c in _seasonControllers)
                int.tryParse(c.text.trim()) ?? 1,
            ]
          : null;
      final posterPath =
          _localPosterPath ?? _trimmedOrNull(_posterUrlController);

      final ManualMedia saved;
      if (_isEditing) {
        final existing = widget.initialMedia!;
        saved = await provider.updateManualMedia(
          existing.copyWith(
            kind: _kind,
            title: _titleController.text.trim(),
            originalTitle: () => _trimmedOrNull(_originalTitleController),
            overview: () => _trimmedOrNull(_overviewController),
            releaseDate: () => _trimmedOrNull(_releaseDateController),
            runtime: () => runtime,
            seasons: () => seasons,
            posterPath: () => posterPath,
            genres: () => _splitCommaList(_genresController),
            originCountries: () => _splitCommaList(_countriesController),
            sourceUrl: () => _trimmedOrNull(_sourceUrlController),
          ),
        );
      } else {
        saved = await provider.createManualMedia(
          kind: _kind,
          title: _titleController.text.trim(),
          originalTitle: _trimmedOrNull(_originalTitleController),
          overview: _trimmedOrNull(_overviewController),
          releaseDate: _trimmedOrNull(_releaseDateController),
          runtime: runtime,
          seasons: seasons,
          posterPath: posterPath,
          genres: _splitCommaList(_genresController),
          originCountries: _splitCommaList(_countriesController),
          sourceUrl: _trimmedOrNull(_sourceUrlController),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _kindLabel(AppLocalizations l10n, ManualMediaKind kind) =>
      switch (kind) {
        ManualMediaKind.movie => l10n.manualMediaKindMovie,
        ManualMediaKind.tv => l10n.manualMediaKindTv,
        ManualMediaKind.video => l10n.manualMediaKindVideo,
        ManualMediaKind.videoSeries => l10n.manualMediaKindVideoSeries,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final localImage = localPosterImageProvider(_localPosterPath);
    final urlText = _posterUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.manualMediaEditTitle : l10n.manualMediaAddTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.manualMediaKindLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in ManualMediaKind.values)
                    ChoiceChip(
                      key: Key('manual_media_kind_${kind.name}'),
                      label: Text(_kindLabel(l10n, kind)),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Reserved slot for future fill helpers (#455, #457, #458).
              Container(
                key: ManualMediaFormPage.fillFromZoneKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  l10n.manualMediaFillFromTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.text2),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ManualMediaFormPage.titleFieldKey,
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.manualMediaTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _originalTitleController,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaOriginalTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _releaseDateController,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaReleaseDateLabel,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ManualMediaFormPage.runtimeFieldKey,
                controller: _runtimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _kind.isSeries
                      ? l10n.manualMediaEpisodeRuntimeLabel
                      : l10n.manualMediaRuntimeLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return l10n.manualMediaInvalidNumber;
                  }
                  return null;
                },
              ),
              if (_kind.isSeries) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.manualMediaSeasonsSection,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      key: ManualMediaFormPage.addSeasonButtonKey,
                      onPressed: _addSeason,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.manualMediaAddSeason),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _seasonControllers.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: Key('manual_media_season_${i + 1}_episodes'),
                          controller: _seasonControllers[i],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                '${l10n.manualMediaSeasonLabel(i + 1)} · ${l10n.manualMediaEpisodesLabel}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final parsed = int.tryParse((v ?? '').trim());
                            if (parsed == null || parsed <= 0) {
                              return l10n.manualMediaInvalidNumber;
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_seasonControllers.length > 1)
                        IconButton(
                          tooltip: l10n.manualMediaRemoveSeason,
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeSeason(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                l10n.manualMediaPosterSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.manualMediaPickImage),
                  ),
                  if (localImage != null || urlText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.manualMediaClearImage,
                      icon: const Icon(Icons.close),
                      onPressed: _clearImage,
                    ),
                  ],
                ],
              ),
              if (localImage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                      image: localImage,
                      width: 88,
                      height: 132,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _posterUrlController,
                enabled: _localPosterPath == null,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaPosterUrlLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _overviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaOverviewLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genresController,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaGenresLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countriesController,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaCountriesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ManualMediaFormPage.sourceUrlFieldKey,
                controller: _sourceUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.manualMediaSourceUrlLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: ManualMediaFormPage.saveButtonKey,
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.manualMediaSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
