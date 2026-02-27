import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../config/home_design_tokens.dart';
import '../../models/course_model.dart';

class ContinueLearningCarousel extends StatelessWidget {
  const ContinueLearningCarousel({
    super.key,
    required this.courses,
    required this.activeIndex,
    required this.onPageChanged,
    required this.onCourseTap,
    required this.onBrowseTap,
    this.isLoading = false,
  });

  final List<CourseModel> courses;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CourseModel> onCourseTap;
  final VoidCallback onBrowseTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue Learning', style: HomeTypography.title),
          const Gap(HomeSpacing.s12),
          if (isLoading)
            _LoadingHeroCard()
          else if (courses.isEmpty)
            _EmptyHeroCard(onBrowseTap: onBrowseTap)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.1, curve: Curves.easeOut)
          else
            _CarouselContent(
                  courses: courses,
                  activeIndex: activeIndex,
                  onPageChanged: onPageChanged,
                  onCourseTap: onCourseTap,
                )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

class _CarouselContent extends StatelessWidget {
  const _CarouselContent({
    required this.courses,
    required this.activeIndex,
    required this.onPageChanged,
    required this.onCourseTap,
  });

  final List<CourseModel> courses;
  final int activeIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CourseModel> onCourseTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: courses.length,
          itemBuilder: (context, index, realIndex) {
            final course = courses[index];
            final progress = ((index + 1) / (courses.length + 1)).clamp(
              0.2,
              0.92,
            );
            return _HeroCourseCard(
                  course: course,
                  progress: progress,
                  onTap: () => onCourseTap(course),
                )
                .animate(key: ValueKey(course.id))
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut);
          },
          options: CarouselOptions(
            viewportFraction: 0.9,
            height: HomeSizes.heroCardHeight,
            enableInfiniteScroll: courses.length > 1,
            enlargeCenterPage: true,
            onPageChanged: (index, _) => onPageChanged(index),
          ),
        ),
        const Gap(HomeSpacing.s12),
        if (courses.length > 1)
          AnimatedSmoothIndicator(
            activeIndex: activeIndex,
            count: courses.length,
            effect: const ExpandingDotsEffect(
              dotHeight: HomeSpacing.s8,
              dotWidth: HomeSpacing.s8,
              spacing: HomeSpacing.s8,
              dotColor: HomeColors.stroke,
              activeDotColor: HomeColors.accentWhite,
            ),
          ),
      ],
    );
  }
}

class _HeroCourseCard extends StatelessWidget {
  const _HeroCourseCard({
    required this.course,
    required this.progress,
    required this.onTap,
  });

  final CourseModel course;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HomeRadius.r24),
      child: Ink(
        decoration: BoxDecoration(
          color: HomeColors.surface1,
          borderRadius: BorderRadius.circular(HomeRadius.r24),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeRadius.r24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if ((course.thumbnailUrl ?? '').isNotEmpty)
                CachedNetworkImage(
                  imageUrl: course.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, _) =>
                      Container(color: HomeColors.surface2),
                  errorWidget: (context, url, error) =>
                      Container(color: HomeColors.surface2),
                )
              else
                Container(color: HomeColors.surface2),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x22000000), Color(0xBB000000)],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: HomeEffects.blur,
                  sigmaY: HomeEffects.blur,
                ),
                child: Container(color: HomeColors.overlay),
              ),
              Padding(
                padding: const EdgeInsets.all(HomeSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TopMetaChip(text: '${course.duration}+ Lecture'),
                        const Gap(HomeSpacing.s8),
                        _TopMetaChip(
                          text: '${course.studentsEnrolled} Enrolled',
                        ),
                      ],
                    ),
                    const Gap(HomeSpacing.s16),
                    Text(
                      course.title,
                      style: HomeTypography.display.copyWith(fontSize: 34),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(HomeSpacing.s8),
                    Text(
                      '${course.category} class',
                      style: HomeTypography.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: HomeSpacing.s12,
                          backgroundColor: HomeColors.surface2,
                          child: Text(
                            course.instructor.isNotEmpty
                                ? course.instructor[0].toUpperCase()
                                : 'I',
                            style: HomeTypography.caption.copyWith(
                              color: HomeColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Gap(HomeSpacing.s8),
                        Expanded(
                          child: Text(
                            course.instructor,
                            style: HomeTypography.body.copyWith(
                              color: HomeColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryCard,
                            borderRadius: BorderRadius.circular(HomeRadius.r20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: HomeSpacing.s8,
                            vertical: HomeSpacing.s8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: HomeSpacing.s20,
                                height: HomeSpacing.s20,
                                decoration: BoxDecoration(
                                  color: AppColors.onPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.onPrimary,
                                  size: HomeSizes.iconSmall,
                                ),
                              ),
                              const Gap(HomeSpacing.s8),
                              Text('Book Now', style: HomeTypography.button),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMetaChip extends StatelessWidget {
  const _TopMetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeSpacing.s12,
        vertical: HomeSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(HomeRadius.r16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: HomeEffects.borderWidth,
        ),
      ),
      child: Text(
        text,
        style: HomeTypography.caption.copyWith(color: AppColors.primarySoft),
      ),
    );
  }
}

class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard({required this.onBrowseTap});

  final VoidCallback onBrowseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: HomeSizes.heroCardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: HomeColors.surface1,
        borderRadius: BorderRadius.circular(HomeRadius.r24),
        border: Border.all(
          color: HomeColors.stroke,
          width: HomeEffects.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(HomeSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No enrolled courses yet', style: HomeTypography.title),
            const Gap(HomeSpacing.s8),
            Text(
              'Start from the catalog and continue here.',
              style: HomeTypography.body,
            ),
            const Spacer(),
            FilledButton(
              onPressed: onBrowseTap,
              style: FilledButton.styleFrom(
                backgroundColor: HomeColors.accentWhite,
                foregroundColor: HomeColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HomeRadius.r12),
                ),
              ),
              child: Text('Browse courses', style: HomeTypography.button),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: HomeColors.surface1,
      highlightColor: HomeColors.surface2,
      child: Container(
        height: HomeSizes.heroCardHeight,
        decoration: BoxDecoration(
          color: HomeColors.surface1,
          borderRadius: BorderRadius.circular(HomeRadius.r24),
        ),
      ),
    );
  }
}
