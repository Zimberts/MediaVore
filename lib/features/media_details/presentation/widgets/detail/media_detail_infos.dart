import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/crew_member.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/person_page.dart';

/// "Info" block: direction or creation, original title, countries and
/// language. Year and length are in the header only.
class MediaDetailInfos extends StatelessWidget {
  const MediaDetailInfos({
    super.key,
    required this.item,
    this.directorName,
    this.director,
  });

  final MediaItem item;

  /// Director of a film, creator of a series.
  final String? directorName;

  /// Full crew member with TMDB ID if available.
  final CrewMember? director;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final countries = item.originCountries ?? const <String>[];
    final language = item.originalLanguage;
    final originalTitle = item.originalTitle;

    final effectiveDirectorName = director?.name ?? directorName;
    final directorId = director?.id;

    final rows = <(String, String, int?)>[
      if (effectiveDirectorName != null && effectiveDirectorName.isNotEmpty)
        (
          item.mediaType == MediaType.tv
              ? l10n.detailInfoCreation
              : l10n.detailInfoDirection,
          effectiveDirectorName,
          directorId,
        ),
      if (originalTitle != null && originalTitle.isNotEmpty)
        (l10n.detailOriginalTitle, originalTitle, null),
      if (countries.isNotEmpty)
        (
          l10n.detailCountry,
          countries
              .map((code) => l10n.detailCountryName(code.toUpperCase()))
              .join(', '),
          null,
        ),
      if (language != null && language.isNotEmpty)
        (
          l10n.detailLanguage,
          l10n.detailLanguageName(language.toLowerCase()),
          null,
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.detailInfos),
        for (final (label, value, personId) in rows)
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
                    child: personId != null
                        ? GestureDetector(
                            onTap: () => PersonPage.show(
                              context,
                              personId: personId,
                              personName: value,
                            ),
                            child: Text(
                              value,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : Text(value, style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
