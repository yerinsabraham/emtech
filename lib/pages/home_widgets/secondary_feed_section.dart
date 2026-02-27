import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../config/home_design_tokens.dart';
import '../../models/course_model.dart';

class FooterActionItem {
  const FooterActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class SecondaryFeedSection extends StatelessWidget {
  const SecondaryFeedSection({
    super.key,
    required this.recommendedCourses,
    required this.onCourseTap,
    required this.footerActions,
  });

  final List<CourseModel> recommendedCourses;
  final ValueChanged<CourseModel> onCourseTap;
  final List<FooterActionItem> footerActions;

  @override
  Widget build(BuildContext context) {
    final instructors = recommendedCourses
        .map((course) => _InstructorItem(course: course))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Instructor', style: HomeTypography.title),
              const Spacer(),
              Text(
                'See More',
                style: HomeTypography.caption.copyWith(
                  color: HomeColors.textPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const Gap(HomeSpacing.s12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: instructors.length,
              separatorBuilder: (context, index) => const Gap(HomeSpacing.s12),
              itemBuilder: (context, index) => _InstructorCard(
                item: instructors[index],
                onTap: () => onCourseTap(instructors[index].course),
              ),
            ),
          ),
          const Gap(HomeSpacing.s20),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: footerActions.length,
              separatorBuilder: (context, index) => const Gap(HomeSpacing.s8),
              itemBuilder: (context, index) =>
                  _FooterTile(item: footerActions[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorItem {
  const _InstructorItem({required this.course});

  final CourseModel course;
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.item, required this.onTap});

  final _InstructorItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeRadius.r20),
        child: SizedBox(
          width: 74,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: HomeColors.surface1,
                  borderRadius: BorderRadius.circular(HomeRadius.r24),
                  boxShadow: const [
                    BoxShadow(
                      color: HomeColors.shadow,
                      blurRadius: HomeEffects.softElevation,
                      offset: HomeEffects.shadowOffset,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: HomeColors.surface1,
                  child: ClipOval(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: (item.course.thumbnailUrl ?? '').isEmpty
                          ? Container(
                              color: HomeColors.surface2,
                              alignment: Alignment.center,
                              child: Text(
                                item.course.instructor.isNotEmpty
                                    ? item.course.instructor[0].toUpperCase()
                                    : 'I',
                                style: HomeTypography.body.copyWith(
                                  color: HomeColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: item.course.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Container(color: HomeColors.surface2),
                            ),
                    ),
                  ),
                ),
              ),
              const Gap(HomeSpacing.s8),
              Text(
                item.course.instructor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: HomeTypography.caption.copyWith(
                  color: HomeColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterTile extends StatelessWidget {
  const _FooterTile({required this.item});

  final FooterActionItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(HomeRadius.r20),
      child: Column(
        children: [
          Container(
            width: HomeSizes.footerTileSize,
            height: HomeSizes.footerTileSize,
            decoration: BoxDecoration(
              color: HomeColors.surface1,
              borderRadius: BorderRadius.circular(HomeRadius.r20),
              border: Border.all(
                color: HomeColors.stroke,
                width: HomeEffects.borderWidth,
              ),
              boxShadow: const [
                BoxShadow(
                  color: HomeColors.shadow,
                  blurRadius: HomeEffects.softElevation,
                  offset: HomeEffects.shadowOffset,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              color: HomeColors.textPrimary,
              size: HomeSizes.iconMedium,
            ),
          ),
          const Gap(HomeSpacing.s8),
          Text(
            item.label,
            style: HomeTypography.caption.copyWith(
              color: HomeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
