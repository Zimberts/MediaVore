import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/app_sheet.dart';
import 'package:mediavore/core/widgets/app_tap_target.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the share sheet for a list: QR Code preview, share QR image, share web link.
Future<void> showListShareSheet(
  BuildContext context, {
  required String listName,
  required String shareLink,
  required GlobalKey qrKey,
  required VoidCallback onShareQrImage,
  required VoidCallback onShareWebLink,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (context) => _ListShareSheetContent(
      listName: listName,
      shareLink: shareLink,
      qrKey: qrKey,
      onShareQrImage: onShareQrImage,
      onShareWebLink: onShareWebLink,
    ),
  );
}

class _ListShareSheetContent extends StatelessWidget {
  const _ListShareSheetContent({
    required this.listName,
    required this.shareLink,
    required this.qrKey,
    required this.onShareQrImage,
    required this.onShareWebLink,
  });

  final String listName;
  final String shareLink;
  final GlobalKey qrKey;
  final VoidCallback onShareQrImage;
  final VoidCallback onShareWebLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.listsShareTitle(listName),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: qrKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: shareLink,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        embeddedImage: const AssetImage('assets/icon/icon.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.listsQrCaption,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.listsQrHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.text2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppTapTarget(
                    onTap: () {
                      Navigator.pop(context);
                      onShareQrImage();
                    },
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onShareQrImage();
                      },
                      icon: const Icon(Icons.image, size: 18),
                      label: Text(l10n.listsShareQrImage),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTapTarget(
                    onTap: () {
                      Navigator.pop(context);
                      onShareWebLink();
                    },
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onShareWebLink();
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(l10n.listsShareWebLink),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
