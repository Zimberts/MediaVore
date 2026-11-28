import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/export_import_serializer.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';
import 'package:mediavore/features/settings/presentation/providers/cache_admin_provider.dart';

/// Key for the "Replace" action in the import preview dialog.
const Key importReplaceButtonKey = Key('data_import_replace');

/// Key for the confirmation button in the replace confirmation dialog.
const Key importReplaceConfirmButtonKey = Key('data_import_replace_confirm');

/// Picks a `.mdv` / `.zip` backup file, previews its contents, asks the user
/// for the import mode (append, merge, replace), and runs the import.
///
/// Returns `true` if an import was completed, `false` if cancelled or failed.
Future<bool> importBackupWithPreview(
  BuildContext context,
  CacheAdminActions provider, {
  String? initialDirectory,
  ValueChanged<bool>? onReadingChanged,
}) async {
  final picked = await FilePicker.pickFile(
    initialDirectory:
        initialDirectory ??
        (Platform.isAndroid ? '/storage/emulated/0/Download' : null),
  );

  if (!context.mounted || picked == null) return false;

  // file_picker >= 12 may return a content:// URI (no local path) on
  // Android: check the name and read through the PlatformFile.
  final name = picked.name.toLowerCase();
  if (!name.endsWith('.mdv') && !name.endsWith('.zip')) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.dataInvalidFile)));
    return false;
  }

  final List<int> bytes;
  final ExportEnvelope envelope;
  try {
    onReadingChanged?.call(true);
    bytes = await picked.readAsBytes();
    if (!context.mounted) return false;
    // Use serializer to normalize and validate on background isolate.
    envelope = await ExportEnvelope.fromZipBytesAsync(bytes);
  } on ParsingException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dataImportFailedReason(e.message))),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.dataImportFailed)));
    }
    return false;
  } finally {
    onReadingChanged?.call(false);
  }

  if (!context.mounted) return false;

  final warnings = envelope.warnings;
  final warningsText = warnings.isEmpty
      ? ''
      : '\n${context.l10n.dataImportSkippedRows(warnings.length)}\n'
            '${warnings.take(5).join('\n')}'
            '${warnings.length > 5 ? '\n…' : ''}\n';

  final mode = await showDialog<ImportMode>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.dataImportPreviewTitle),
      content: Text(
        context.l10n.dataImportPreviewMessage(
          envelope.seen.length,
          envelope.likes.length,
          envelope.notifications.length,
          envelope.lists.length,
          warningsText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, ImportMode.append),
          child: Text(context.l10n.dataAppend),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, ImportMode.merge),
          child: Text(context.l10n.dataMerge),
        ),
        TextButton(
          key: importReplaceButtonKey,
          onPressed: () => Navigator.pop(dialogContext, ImportMode.replace),
          child: Text(
            context.l10n.dataReplace,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );

  if (mode == null || !context.mounted) return false;

  if (mode == ImportMode.replace) {
    final confirmed = await _confirmReplace(context);
    if (!confirmed || !context.mounted) return false;
  }

  await provider.importAllData(bytes, mode: mode);
  if (!context.mounted) return true;

  final message = switch (mode) {
    ImportMode.append => context.l10n.dataImportedAppended,
    ImportMode.merge => context.l10n.dataImportedMerged,
    ImportMode.replace => context.l10n.dataImportedReplaced,
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  return true;
}

Future<bool> _confirmReplace(BuildContext context) async {
  final colors = context.appColors;
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.dataReplaceTitle),
          content: Text(context.l10n.dataReplaceMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              key: importReplaceConfirmButtonKey,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                context.l10n.dataReplaceConfirm,
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
