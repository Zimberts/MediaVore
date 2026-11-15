import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/cast_member.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/media_details/presentation/pages/actor_detail_page.dart';

/// "Cast" section: a horizontal row of people; a tap pushes the person page.
class MediaDetailCast extends StatelessWidget {
  const MediaDetailCast({super.key, required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.detailCast),
        SizedBox(
          height: 96 + 84 * textScale,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final member = cast[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => ActorDetailPage(
                      actorId: member.id,
                      actorName: member.name,
                    ),
                  ),
                ),
                child: Container(
                  width: 100,
                  margin: const EdgeInsetsDirectional.only(end: 12),
                  child: Column(
                    children: [
                      member.profilePath != null &&
                              !Platform.environment.containsKey('FLUTTER_TEST')
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                'https://image.tmdb.org/t/p/w185${member.profilePath}',
                              ),
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: colors.placeholder,
                              child: Icon(Icons.person, color: colors.text2),
                            ),
                      const SizedBox(height: 4),
                      Text(
                        member.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        member.character,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
