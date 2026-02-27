import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../config/home_design_tokens.dart';

class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.items});

  final List<HomeQuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: HomeTypography.title),
          const Gap(HomeSpacing.s12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Gap(HomeSpacing.s8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _ActionCard(item: item)
                    .animate(delay: (index * 70).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.15, curve: Curves.easeOut);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.item});

  final HomeQuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(HomeRadius.r24),
        child: Ink(
          height: 56,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeSpacing.s12,
              vertical: HomeSpacing.s8,
            ),
            child: Row(
              children: [
                Container(
                  width: HomeSpacing.s32,
                  height: HomeSpacing.s32,
                  decoration: BoxDecoration(
                    color: (item.accentColor ?? AppColors.primary).withValues(
                      alpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(HomeRadius.r16),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.accentColor ?? AppColors.primary,
                    size: HomeSizes.iconMedium,
                  ),
                ),
                const Gap(HomeSpacing.s12),
                Text(
                  item.label,
                  style: HomeTypography.body.copyWith(
                    color: HomeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
