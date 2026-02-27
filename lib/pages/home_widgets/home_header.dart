import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/home_design_tokens.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.stats,
    this.notificationCount = 0,
  });

  final String displayName;
  final String? photoUrl;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final List<HomeHeaderStat> stats;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeSpacing.s16,
        vertical: HomeSpacing.s8,
      ),
      child: Column(
        children: [
          Row(
                children: [
                  Container(
                    width: HomeSizes.avatar,
                    height: HomeSizes.avatar,
                    decoration: BoxDecoration(
                      color: HomeColors.surface2,
                      borderRadius: BorderRadius.circular(HomeRadius.r12),
                      border: Border.all(
                        color: HomeColors.stroke,
                        width: HomeEffects.borderWidth,
                      ),
                    ),
                    child: photoUrl != null && photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(HomeRadius.r12),
                            child: Image.network(photoUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(
                            Iconsax.user,
                            color: HomeColors.textPrimary,
                            size: HomeSizes.iconMedium,
                          ),
                  ),
                  const Gap(HomeSpacing.s12),
                  Expanded(
                    child: Text(
                      displayName,
                      style: HomeTypography.body.copyWith(
                        color: HomeColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _HeaderIconButton(
                    icon: Iconsax.search_normal,
                    onTap: onSearchTap,
                  ),
                  const Gap(HomeSpacing.s8),
                  Stack(
                    children: [
                      _HeaderIconButton(
                        icon: Iconsax.notification,
                        onTap: onNotificationTap,
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: HomeSpacing.s8,
                          top: HomeSpacing.s8,
                          child: Container(
                            width: HomeSpacing.s8,
                            height: HomeSpacing.s8,
                            decoration: const BoxDecoration(
                              color: HomeColors.accentWhite,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.08, curve: Curves.easeOut),
          const Gap(HomeSpacing.s12),
          SizedBox(
                height: HomeSizes.chipHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: HomeSpacing.s8),
                  itemBuilder: (context, index) {
                    final stat = stats[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeSpacing.s12,
                      ),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? AppColors.primaryMuted
                            : HomeColors.surface1,
                        borderRadius: BorderRadius.circular(HomeRadius.r16),
                        border: Border.all(
                          color: index == 0
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : HomeColors.stroke,
                          width: HomeEffects.borderWidth,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: RichText(
                        text: TextSpan(
                          style: HomeTypography.caption,
                          children: [
                            TextSpan(
                              text: stat.value,
                              style: HomeTypography.body.copyWith(
                                color: index == 0
                                    ? AppColors.primarySoft
                                    : HomeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' ${stat.label}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
              .animate(delay: 120.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut),
          const Gap(HomeSpacing.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              'assets/images/emtech_logo.svg',
              height: 18,
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

class HomeHeaderStat {
  const HomeHeaderStat({required this.value, required this.label});

  final String value;
  final String label;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeSizes.avatar,
      height: HomeSizes.avatar,
      decoration: BoxDecoration(
        color: HomeColors.surface1,
        borderRadius: BorderRadius.circular(HomeRadius.r12),
        border: Border.all(
          color: HomeColors.stroke,
          width: HomeEffects.borderWidth,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: HomeSpacing.s20,
        onPressed: onTap,
        icon: Icon(
          icon,
          color: HomeColors.textPrimary,
          size: HomeSizes.iconMedium,
        ),
      ),
    );
  }
}
