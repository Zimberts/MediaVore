import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/services/app_update_service.dart';
import 'package:mediavore/features/settings/presentation/providers/app_update_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UpdateUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _defaultUrlLauncher(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[AppUpdateDialog] launchUrl failed: $e');
    return false;
  }
}

/// Returns the localized error message for [kind].
String appUpdateErrorMessage(AppLocalizations l10n, AppUpdateErrorKind? kind) {
  switch (kind) {
    case AppUpdateErrorKind.network:
      return l10n.updateErrorNetwork;
    case AppUpdateErrorKind.rateLimit:
      return l10n.updateErrorRateLimit;
    case AppUpdateErrorKind.server:
      return l10n.updateErrorServer;
    case AppUpdateErrorKind.parsing:
      return l10n.updateErrorParsing;
    case AppUpdateErrorKind.checksumMismatch:
      return l10n.updateErrorChecksum;
    case AppUpdateErrorKind.noApkAsset:
      return l10n.updateErrorNoApk;
    case AppUpdateErrorKind.installFailed:
      return l10n.updateErrorInstallFailed;
    case AppUpdateErrorKind.unknown:
    case null:
      return l10n.updateErrorUnknown;
  }
}

/// Displays release notes, download progress, and install / browser actions
/// for an available [GitHubRelease].
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.release, this.urlLauncher});

  final GitHubRelease release;

  /// Overridable for tests; defaults to `url_launcher`.
  final UpdateUrlLauncher? urlLauncher;

  static const Key downloadButtonKey = Key('update_dialog_download_button');
  static const Key installButtonKey = Key('update_dialog_install_button');
  static const Key openBrowserButtonKey = Key(
    'update_dialog_open_browser_button',
  );
  static const Key cancelButtonKey = Key('update_dialog_cancel_button');
  static const Key laterButtonKey = Key('update_dialog_later_button');

  Future<void> _openReleasePage() async {
    final uri = Uri.tryParse(release.htmlUrl);
    if (uri == null) return;
    final launcher = urlLauncher ?? _defaultUrlLauncher;
    await launcher(uri);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppUpdateProvider>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = provider.status;
    final changelog = release.body.trim().isEmpty
        ? l10n.updateNoChangelog
        : release.body.trim();

    return AlertDialog(
      title: Text(l10n.updateAvailableTitle(release.tagName)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: SelectableText(
                  changelog,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (!provider.isAndroid) ...[
              const SizedBox(height: 12),
              Text(
                l10n.updateIosNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (status == AppUpdateStatus.downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: provider.downloadProgress),
              const SizedBox(height: 8),
              Text(
                l10n.updateDownloading(
                  (provider.downloadProgress * 100).round().clamp(0, 100),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ] else if (status == AppUpdateStatus.verifying) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                l10n.updateVerifyingSha256,
                style: theme.textTheme.bodySmall,
              ),
            ] else if (status == AppUpdateStatus.error) ...[
              const SizedBox(height: 16),
              Text(
                appUpdateErrorMessage(l10n, provider.errorKind),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(context, provider, l10n),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppUpdateProvider provider,
    AppLocalizations l10n,
  ) {
    final status = provider.status;

    if (!provider.isAndroid) {
      return [
        TextButton(
          key: laterButtonKey,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateLater),
        ),
        FilledButton.icon(
          key: openBrowserButtonKey,
          onPressed: _openReleasePage,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.updateOpenReleasePage),
        ),
      ];
    }

    if (status == AppUpdateStatus.downloading ||
        status == AppUpdateStatus.verifying) {
      return [
        TextButton(
          key: cancelButtonKey,
          onPressed: status == AppUpdateStatus.downloading
              ? provider.cancelDownload
              : null,
          child: Text(l10n.commonCancel),
        ),
      ];
    }

    if (status == AppUpdateStatus.readyToInstall ||
        status == AppUpdateStatus.installing) {
      return [
        TextButton(
          key: laterButtonKey,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateLater),
        ),
        TextButton(
          key: openBrowserButtonKey,
          onPressed: _openReleasePage,
          child: Text(l10n.updateOpenReleasePage),
        ),
        FilledButton(
          key: installButtonKey,
          onPressed: status == AppUpdateStatus.installing
              ? null
              : provider.installDownloadedApk,
          child: Text(l10n.updateInstallButton),
        ),
      ];
    }

    if (status == AppUpdateStatus.error) {
      return [
        TextButton(
          key: laterButtonKey,
          onPressed: () {
            provider.dismissError();
            Navigator.of(context).pop();
          },
          child: Text(l10n.updateLater),
        ),
        FilledButton.icon(
          key: openBrowserButtonKey,
          onPressed: _openReleasePage,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(l10n.updateOpenReleasePage),
        ),
      ];
    }

    return [
      TextButton(
        key: laterButtonKey,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.updateLater),
      ),
      TextButton(
        key: openBrowserButtonKey,
        onPressed: _openReleasePage,
        child: Text(l10n.updateOpenReleasePage),
      ),
      FilledButton(
        key: downloadButtonKey,
        onPressed: provider.downloadAndInstall,
        child: Text(l10n.updateDownloadAndInstall),
      ),
    ];
  }
}
