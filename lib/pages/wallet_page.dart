import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../config/home_design_tokens.dart';
import '../models/transaction_model.dart';
import '../screens/earn_emc_page.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_page_header.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userModel = authService.userModel;
    final emcBalance = userModel?.emcBalance ?? 0;
    final userId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(HomeSpacing.s16),

              AppPageHeader(
                title: 'Wallet',
                subtitle: 'EMC Token Balance',
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08),

              const Gap(HomeSpacing.s20),

              _BalanceCard(
                    balance: emcBalance,
                    onEarn: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EarnEmcPage()),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut),

              const Gap(HomeSpacing.s24),

              Text(
                'Recent Transactions',
                style: HomeTypography.title,
              ).animate().fadeIn(delay: 140.ms, duration: 300.ms),

              const Gap(HomeSpacing.s12),

              Expanded(
                child: userId == null
                    ? const _EmptyState(
                        icon: Iconsax.lock,
                        message: 'Log in to view transactions',
                      )
                    : StreamBuilder<List<TransactionModel>>(
                        stream: firestoreService.getTransactions(userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Could not load transactions',
                                style: HomeTypography.body,
                              ),
                            );
                          }
                          final list =
                              snapshot.data ?? const <TransactionModel>[];
                          if (list.isEmpty) {
                            return const _EmptyState(
                              icon: Iconsax.receipt,
                              message: 'No transactions yet',
                              hint: 'Earn or spend tokens to see history',
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.only(
                              bottom: HomeSpacing.s32,
                            ),
                            itemCount: list.length,
                            separatorBuilder: (_, _) =>
                                const Gap(HomeSpacing.s8),
                            itemBuilder: (context, i) =>
                                _TransactionTile(tx: list[i])
                                    .animate(delay: (i * 40).ms)
                                    .fadeIn(duration: 280.ms)
                                    .slideX(begin: 0.08),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Balance Card ---------------------------------------------------------

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onEarn});

  final num balance;
  final VoidCallback onEarn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HomeSpacing.s24),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryCard,
        borderRadius: BorderRadius.circular(HomeRadius.r24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimary,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: HomeTypography.caption.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          const Gap(HomeSpacing.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.toStringAsFixed(0),
                style: HomeTypography.display.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 44,
                ),
              ),
              const Gap(HomeSpacing.s8),
              Padding(
                padding: const EdgeInsets.only(bottom: HomeSpacing.s8),
                child: Text(
                  'EMC',
                  style: HomeTypography.body.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const Gap(HomeSpacing.s20),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  icon: Iconsax.add_circle,
                  label: 'Earn',
                  onTap: onEarn,
                ),
              ),
              const Gap(HomeSpacing.s12),
              Expanded(
                child: _CardButton(
                  icon: Iconsax.shopping_bag,
                  label: 'Spend',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(HomeRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeRadius.r12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: HomeSpacing.s12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.onPrimary, size: HomeSizes.iconSmall),
              const Gap(HomeSpacing.s8),
              Text(
                label,
                style: HomeTypography.button.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Transaction Tile ------------------------------------------------------

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final TransactionModel tx;

  static IconData _iconFor(String desc) {
    if (desc.contains('Purchase')) return Iconsax.shopping_bag;
    if (desc.contains('Task')) return Iconsax.task_square;
    if (desc.contains('Reward') || desc.contains('Signup')) return Iconsax.gift;
    if (desc.contains('Quiz')) return Iconsax.document_text;
    return Iconsax.arrow_swap_horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.type == 'earn';
    final iconColor = isEarned ? AppColors.teal : AppColors.accent;
    final bgColor = isEarned ? AppColors.tealMuted : AppColors.accentMuted;
    final amountColor = isEarned ? AppColors.teal : const Color(0xFFFF6B6B);
    final amountText =
        '${isEarned ? '+' : '-'}${tx.amount.toStringAsFixed(0)} EMC';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeSpacing.s16,
        vertical: HomeSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: HomeColors.surface1,
        borderRadius: BorderRadius.circular(HomeRadius.r16),
        border: Border.all(
          color: AppColors.stroke,
          width: HomeEffects.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: HomeSizes.avatar + 8,
            height: HomeSizes.avatar + 8,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(HomeRadius.r12),
            ),
            child: Icon(
              _iconFor(tx.description),
              color: iconColor,
              size: HomeSizes.iconMedium,
            ),
          ),
          const Gap(HomeSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: HomeTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Text(_formatAge(tx.createdAt), style: HomeTypography.caption),
              ],
            ),
          ),
          Text(
            amountText,
            style: HomeTypography.body.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatAge(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// --- Empty State ----------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.hint});

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(HomeSpacing.s20),
            decoration: const BoxDecoration(
              color: AppColors.primaryMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primarySoft,
              size: HomeSizes.iconLarge,
            ),
          ),
          const Gap(HomeSpacing.s16),
          Text(message, style: HomeTypography.title),
          if (hint != null) ...[
            const Gap(HomeSpacing.s8),
            Text(
              hint!,
              style: HomeTypography.body,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
