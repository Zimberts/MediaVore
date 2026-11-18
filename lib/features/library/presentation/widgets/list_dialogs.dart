import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/list_share_codec.dart';
import 'package:mediavore/core/widgets/app_dialog.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// A list received through a share link or a QR code.
@immutable
class SharedList {
  const SharedList({required this.name, required this.entries});

  final String name;

  /// Entries as `id:type`.
  final List<String> entries;
}

/// Builds the camera view of [showListScanner]; calls `onCode` with each
/// decoded value. Tests replace it, the camera being unavailable there.
typedef ListScannerBuilder =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

/// Whether [link] looks like a MediaVore share link.
bool isSharedListLink(String link) =>
    link.startsWith('mediavore://share') ||
    link.startsWith('https://mediavore.app/share');

/// Reads the list carried by a share [link]; `null` when it has none.
SharedList? parseSharedListLink(String link) {
  final uri = Uri.tryParse(link.trim());
  if (uri == null) return null;
  final payload = ListShareCodec.decodeUri(uri);
  if (payload == null || payload.entries.isEmpty) return null;
  return SharedList(
    name: payload.name,
    entries: payload.entries.map((e) => e.toString()).toList(),
  );
}

/// Asks for a single line of text; completes with the trimmed text, or `null`
/// when the dialog is dismissed.
Future<String?> _promptText({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String? message,
  String? label,
  String? hint,
  String initialText = '',
}) async {
  var text = initialText;
  final confirmed = await showAppDialog<bool>(
    context: context,
    title: title,
    message: message,
    content: _PromptField(
      initialText: initialText,
      label: label,
      hint: hint,
      onChanged: (value) => text = value,
    ),
    actions: [
      AppDialogAction(label: context.l10n.commonCancel),
      AppDialogAction(label: confirmLabel, value: true),
    ],
  );
  return confirmed == true ? text.trim() : null;
}

class _PromptField extends StatefulWidget {
  const _PromptField({
    required this.initialText,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final String initialText;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
      ),
    );
  }
}

/// Asks for a name and creates the list. Completes with the name of the new
/// list, or `null` when nothing was created.
Future<String?> showCreateListDialog(BuildContext context) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  final name = await _promptText(
    context: context,
    title: l10n.listsNewList,
    hint: l10n.listsNameHint,
    confirmLabel: l10n.commonCreate,
  );
  if (name == null || name.isEmpty) return null;
  final taken = provider.listNames.any(
    (existing) => existing.toLowerCase() == name.toLowerCase(),
  );
  if (taken || name.toLowerCase() == 'watchlist') {
    showAppMessage(l10n.libraryListNameTaken(name));
    return null;
  }
  await provider.createList(name);
  return name;
}

/// Opens the camera to scan the QR code of a shared list. Completes with the
/// scanned link, or `null` when closed.
Future<String?> showListScanner(
  BuildContext context, {
  ListScannerBuilder? scannerBuilder,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      var done = false;
      void onCode(String code) {
        if (done || !isSharedListLink(code)) return;
        done = true;
        Navigator.pop(context, code);
      }

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            AppBar(
              title: Text(context.l10n.listsScanTitle),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: context.l10n.commonClose,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: scannerBuilder != null
                  ? scannerBuilder(context, onCode)
                  : MobileScanner(
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          final code = barcode.rawValue;
                          if (code != null) onCode(code);
                        }
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.listsScanHint),
            ),
          ],
        ),
      );
    },
  );
}

/// Asks for a share link. Completes with the list it carries, or `null` when
/// cancelled or when the link is not valid (reported to the user).
Future<SharedList?> showImportLinkDialog(BuildContext context) async {
  final l10n = context.l10n;
  final link = await _promptText(
    context: context,
    title: l10n.listsImportViaLink,
    label: l10n.listsShareLinkLabel,
    hint: l10n.listsPasteLinkHint,
    confirmLabel: l10n.commonImport,
  );
  if (link == null || link.isEmpty) return null;
  final shared = parseSharedListLink(link);
  if (shared == null) showAppMessage(l10n.listsInvalidLink);
  return shared;
}

/// Confirms the import of [shared] under an editable name, then imports it.
/// Completes with the name of the imported list, or `null` when cancelled.
Future<String?> confirmListImport(
  BuildContext context,
  SharedList shared,
) async {
  final l10n = context.l10n;
  final provider = context.read<SearchProvider>();
  final typed = await _promptText(
    context: context,
    title: l10n.listsConfirmImport,
    message: l10n.importListMessage(shared.entries.length),
    label: l10n.importListNameLabel,
    hint: l10n.importListNameHint,
    initialText: shared.name,
    confirmLabel: l10n.commonConfirm,
  );
  if (typed == null) return null;
  final name = typed.isEmpty ? shared.name : typed;
  await provider.importList(name, shared.entries);
  showAppMessage(l10n.libraryListImported(name));
  return name;
}

/// Scans a QR code, then confirms and imports the list it carries.
Future<String?> importListFromQr(
  BuildContext context, {
  ListScannerBuilder? scannerBuilder,
}) async {
  final link = await showListScanner(context, scannerBuilder: scannerBuilder);
  if (link == null || !context.mounted) return null;
  final shared = parseSharedListLink(link);
  if (shared == null) {
    showAppMessage(context.l10n.listsInvalidLink);
    return null;
  }
  return confirmListImport(context, shared);
}

/// Asks for a share link, then confirms and imports the list it carries.
Future<String?> importListFromLink(BuildContext context) async {
  final shared = await showImportLinkDialog(context);
  if (shared == null || !context.mounted) return null;
  return confirmListImport(context, shared);
}

enum _ImportSource { qr, link }

/// "Import a list": lets the user pick QR code or link, then runs the import.
/// Completes with the name of the imported list, or `null`.
Future<String?> showImportListMenu(
  BuildContext context, {
  ListScannerBuilder? scannerBuilder,
}) async {
  final l10n = context.l10n;
  final source = await showAppMenu<_ImportSource>(
    context: context,
    title: l10n.importListTitle,
    items: [
      AppMenuItem(
        value: _ImportSource.qr,
        label: l10n.listsScanQr,
        subtitle: l10n.listsScanHint,
        icon: Icons.qr_code_scanner,
      ),
      AppMenuItem(
        value: _ImportSource.link,
        label: l10n.listsImportViaLink,
        subtitle: l10n.listsPasteLinkHint,
        icon: Icons.link,
      ),
    ],
  );
  if (source == null || !context.mounted) return null;
  return switch (source) {
    _ImportSource.qr => importListFromQr(
      context,
      scannerBuilder: scannerBuilder,
    ),
    _ImportSource.link => importListFromLink(context),
  };
}
