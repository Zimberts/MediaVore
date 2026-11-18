import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/library/presentation/widgets/list_dialogs.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mediavore/features/together/presentation/pages/together_results_page.dart';
import 'package:mediavore/features/together/presentation/providers/together_session_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Screen to configure and run a Together session by exchanging list QR codes.
class TogetherPage extends StatefulWidget {
  const TogetherPage({
    super.key,
    this.scannerBuilder,
  });

  /// Allows tests to mock the QR scanner without camera access.
  final ListScannerBuilder? scannerBuilder;

  @override
  State<TogetherPage> createState() => _TogetherPageState();
}

class _TogetherPageState extends State<TogetherPage> {
  int _currentQrIndex = 0;

  Future<void> _scanFriendQr() async {
    final l10n = context.l10n;
    final session = context.read<TogetherSessionProvider>();

    final code = await showListScanner(
      context,
      scannerBuilder: widget.scannerBuilder,
    );
    if (code == null) return;

    final payload = ListShareCodec.parse(code);
    if (payload == null) {
      showAppMessage(l10n.listsInvalidLink);
      return;
    }

    final participantName =
        payload.name.trim().isEmpty ? 'Ami' : payload.name.trim();

    session.addParticipantChunk(
      name: participantName,
      part: payload.part,
      totalParts: payload.totalParts,
      entries: payload.entries,
    );

    if (payload.totalParts > 1 && payload.part < payload.totalParts) {
      showAppMessage(
        l10n.togetherScanNextPart(payload.part + 1, payload.totalParts),
      );
    }
  }

  void _confirmResetSession() {
    final l10n = context.l10n;
    final session = context.read<TogetherSessionProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.togetherResetSession),
        content: Text(l10n.togetherResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              session.reset();
              setState(() => _currentQrIndex = 0);
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();
    final session = context.watch<TogetherSessionProvider>();

    final hostListEntries = ListShareCodec.parseEntries(
      searchProvider.listEntries[session.selectedListName] ?? const [],
    );

    final hostUrls = ListShareCodec.createTogetherUrls(
      name: l10n.togetherYouHost,
      entries: hostListEntries,
      chunkSize: 150,
    );

    if (_currentQrIndex >= hostUrls.length) {
      _currentQrIndex = 0;
    }

    final availableLists = <String>{
      'watchlist',
      ...searchProvider.listNames,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.togetherSessionSetup),
        actions: [
          if (session.hasSession)
            IconButton(
              key: const Key('together_reset_button'),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.togetherResetSession,
              onPressed: _confirmResetSession,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. "On choisit" segmented control
          Text(
            l10n.togetherWeAreChoosing,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<MediaType?>(
            key: const Key('together_type_segmented_button'),
            segments: [
              ButtonSegment<MediaType?>(
                value: null,
                label: Text(l10n.togetherChoiceAny),
              ),
              ButtonSegment<MediaType?>(
                value: MediaType.movie,
                label: Text(l10n.togetherChoiceMovie),
              ),
              ButtonSegment<MediaType?>(
                value: MediaType.tv,
                label: Text(l10n.togetherChoiceTv),
              ),
            ],
            selected: {session.selectedType},
            onSelectionChanged: (selection) {
              session.setSelectedType(selection.first);
            },
          ),
          const SizedBox(height: 16),

          // 2. "Ma liste" dropdown selector
          Row(
            children: [
              Text(
                l10n.togetherMyListLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  key: const Key('together_list_dropdown'),
                  value: availableLists.contains(session.selectedListName)
                      ? session.selectedListName
                      : 'watchlist',
                  isExpanded: true,
                  items: availableLists.map((name) {
                    final displayName =
                        name == 'watchlist' ? l10n.listsWatchlist : name;
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      session.setSelectedListName(value);
                      setState(() => _currentQrIndex = 0);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Host QR code card
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    key: const Key('together_qr_image'),
                    data: hostUrls[_currentQrIndex],
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                  if (hostUrls.length > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.black),
                          onPressed: _currentQrIndex > 0
                              ? () => setState(() => _currentQrIndex--)
                              : null,
                        ),
                        Text(
                          l10n.togetherMultiQrPart(
                            _currentQrIndex + 1,
                            hostUrls.length,
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.black),
                          onPressed: _currentQrIndex < hostUrls.length - 1
                              ? () => setState(() => _currentQrIndex++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Warning notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: colors.text2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.togetherWarningNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.text2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Scan a friend's QR button
          ElevatedButton.icon(
            key: const Key('together_scan_button'),
            onPressed: _scanFriendQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.togetherScanQrButton),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colors.primary,
              foregroundColor: contrastingForeground(colors.primary),
            ),
          ),
          const SizedBox(height: 24),

          // 6. Participants list
          SectionHeader(
            title:
                '${l10n.togetherParticipantsTitle} (${session.participants.length + 1})',
          ),
          const SizedBox(height: 8),

          // Host participant entry
          ListTile(
            key: const Key('together_participant_host'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: colors.primary,
              child: Text(
                'MOI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: contrastingForeground(colors.primary),
                ),
              ),
            ),
            title: Text(
              l10n.togetherYouHost,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(l10n.togetherItemsCount(hostListEntries.length)),
          ),

          // Scanned friends entries
          for (final participant in session.participants)
            ListTile(
              key: Key('together_participant_${participant.name}'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colors.duo,
                child: Text(
                  participant.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: contrastingForeground(colors.duo),
                  ),
                ),
              ),
              title: Text(
                participant.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                participant.isComplete
                    ? l10n.togetherItemsCount(participant.entries.length)
                    : '${l10n.togetherItemsCount(participant.entries.length)} • ${l10n.togetherMultiQrPart(participant.scannedParts.length, participant.totalParts)}',
              ),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle_outline, color: colors.danger),
                tooltip: l10n.commonDelete,
                onPressed: () => session.removeParticipant(participant.name),
              ),
            ),

          const SizedBox(height: 16),

          // 7. Prompt text if no friends scanned
          if (session.participants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Text(
                  l10n.togetherScanPrompt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.text2,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // 8. "Voir les titres en commun" button
          ElevatedButton(
            key: const Key('together_see_common_button'),
            onPressed: session.participants.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TogetherResultsPage(),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: colors.success,
              foregroundColor: contrastingForeground(colors.success),
            ),
            child: Text(
              l10n.togetherSeeCommonTitles,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
