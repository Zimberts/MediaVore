import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';

/// "Info" block: direction or creation, original title, countries and
/// language. Year and length are in the header only.
class MediaDetailInfos extends StatelessWidget {
  const MediaDetailInfos({super.key, required this.item, this.directorName});

  final MediaItem item;

  /// Director of a film, creator of a series.
  final String? directorName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countries = item.originCountries ?? const <String>[];
    final language = item.originalLanguage;
    final originalTitle = item.originalTitle;
    final rows = <(String, String)>[
      if (directorName != null && directorName!.isNotEmpty)
        (
          item.mediaType == MediaType.tv
              ? l10n.detailInfoCreation
              : l10n.detailInfoDirection,
          directorName!,
        ),
      if (originalTitle != null && originalTitle.isNotEmpty)
        (l10n.detailOriginalTitle, originalTitle),
      if (countries.isNotEmpty)
        (
          l10n.detailCountry,
          countries
              .map((code) => l10n.detailCountryName(code.toUpperCase()))
              .join(', '),
        ),
      if (language != null && language.isNotEmpty)
        (l10n.detailLanguage, l10n.detailLanguageName(language.toLowerCase())),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.detailInfos),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.text2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(value, style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
