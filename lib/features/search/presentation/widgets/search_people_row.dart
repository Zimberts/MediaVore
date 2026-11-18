import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/person_summary.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/person_page.dart';

/// Horizontal row of person search results in Discover mode.
class SearchPeopleRow extends StatelessWidget {
  final List<PersonSummary> people;

  const SearchPeopleRow({super.key, required this.people});

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();

    final colors = context.appColors;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          key: const Key('search_people_section_header'),
          title: context.l10n.discoverPeopleSection,
        ),
        SizedBox(
          height: 96 + 56 * textScale,
          child: ListView.builder(
            key: const Key('search_people_list_view'),
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              final hasProfile =
                  person.profilePath != null &&
                  person.profilePath!.isNotEmpty &&
                  !Platform.environment.containsKey('FLUTTER_TEST');

              final subtitle =
                  person.knownForDepartment ??
                  (person.knownForTitles.isNotEmpty
                      ? person.knownForTitles.first
                      : null);

              return Semantics(
                button: true,
                label: person.name,
                child: InkWell(
                  key: Key('search_person_${person.id}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => PersonPage.show(
                    context,
                    personId: person.id,
                    personName: person.name,
                  ),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsetsDirectional.only(end: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: colors.surface2,
                          backgroundImage: hasProfile
                              ? CachedNetworkImageProvider(
                                  'https://image.tmdb.org/t/p/w185${person.profilePath}',
                                )
                              : null,
                          child: hasProfile
                              ? null
                              : Text(
                                  _initials(person.name),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colors.text2,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: colors.text2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
