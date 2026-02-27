import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../config/home_design_tokens.dart';

class SessionSelector extends StatelessWidget {
  const SessionSelector({
    super.key,
    required this.sessions,
    required this.selectedSession,
    required this.onSessionChanged,
  });

  final List<String> sessions;
  final String selectedSession;
  final ValueChanged<String> onSessionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Sessions', style: HomeTypography.title),
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
            height: HomeSizes.chipHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const Gap(HomeSpacing.s8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isSelected = session == selectedSession;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSessionChanged(session),
                    borderRadius: BorderRadius.circular(HomeRadius.r20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: HomeSpacing.s16,
                        vertical: HomeSpacing.s8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : HomeColors.surface1,
                        borderRadius: BorderRadius.circular(HomeRadius.r20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : HomeColors.stroke,
                          width: HomeEffects.borderWidth,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.shadowPrimary,
                                  blurRadius: HomeEffects.softElevation,
                                  offset: HomeEffects.shadowOffset,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        session,
                        style: HomeTypography.body.copyWith(
                          color: isSelected
                              ? AppColors.onPrimary
                              : HomeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
