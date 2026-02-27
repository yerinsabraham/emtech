import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../config/home_design_tokens.dart';
import '../screens/admin/admin_panel_page.dart';
import '../screens/login_page.dart';
import '../services/auth_service.dart';
import '../widgets/app_page_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    final currentUser = authService.currentUser;

    final displayName =
        userModel?.name ?? currentUser?.displayName ?? 'Emtech Student';
    final email = currentUser?.email ?? 'student@emtech.edu';
    final emcBalance = userModel?.emcBalance ?? 0;
    final enrolledCount = userModel?.enrolledCourses.length ?? 0;
    final session = userModel?.session ?? 'Not enrolled';
    final role = userModel?.role ?? 'student';

    final menuItems = [
      if (authService.isAdmin)
        _MenuItem(
          icon: Iconsax.shield,
          label: 'Admin Dashboard',
          accentColor: const Color(0xFFFF6B6B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPanelPage()),
          ),
        ),
      _MenuItem(
        icon: Iconsax.user_edit,
        label: 'Edit Profile',
        onTap: () => Navigator.pushNamed(context, '/edit-profile'),
      ),
      _MenuItem(
        icon: Iconsax.clock,
        label: 'Learning History',
        onTap: () => Navigator.pushNamed(context, '/learning-history'),
      ),
      _MenuItem(
        icon: Iconsax.bookmark,
        label: 'Saved Courses',
        onTap: () => Navigator.pushNamed(context, '/saved-courses'),
      ),
      _MenuItem(
        icon: Iconsax.award,
        label: 'Achievements',
        onTap: () => Navigator.pushNamed(context, '/achievements'),
      ),
      _MenuItem(
        icon: Iconsax.setting,
        label: 'Settings',
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
      _MenuItem(
        icon: Iconsax.message_question,
        label: 'Help & Support',
        onTap: () => Navigator.pushNamed(context, '/support'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(HomeSpacing.s16),

              const AppPageHeader(
                title: 'Profile',
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.08),

              const Gap(HomeSpacing.s20),

              _ProfileCard(
                    displayName: displayName,
                    email: email,
                    photoUrl: userModel?.photoUrl,
                    role: role,
                    session: session,
                  )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut),

              const Gap(HomeSpacing.s16),

              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'EMC Tokens',
                      value: emcBalance.toStringAsFixed(0),
                      icon: Iconsax.wallet,
                      color: AppColors.accent,
                    ),
                  ),
                  const Gap(HomeSpacing.s12),
                  Expanded(
                    child: _StatChip(
                      label: 'Courses',
                      value: enrolledCount.toString(),
                      icon: Iconsax.book_saved,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 140.ms, duration: 300.ms),

              const Gap(HomeSpacing.s20),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: HomeSpacing.s32),
                  itemCount: menuItems.length + 1,
                  separatorBuilder: (_, _) => const Gap(HomeSpacing.s8),
                  itemBuilder: (context, i) {
                    if (i < menuItems.length) {
                      return _MenuTile(item: menuItems[i])
                          .animate(delay: (i * 35).ms)
                          .fadeIn(duration: 260.ms)
                          .slideX(begin: 0.08);
                    }
                    return _LogoutTile(authService: authService)
                        .animate(delay: (menuItems.length * 35 + 40).ms)
                        .fadeIn(duration: 260.ms);
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

// --- Profile Card ----------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.session,
  });

  final String displayName;
  final String email;
  final String? photoUrl;
  final String role;
  final String session;

  static Color _roleColor(String r) {
    switch (r) {
      case 'admin':
        return const Color(0xFFFF6B6B);
      case 'lecturer':
        return AppColors.primary;
      default:
        return AppColors.teal;
    }
  }

  static IconData _roleIcon(String r) {
    switch (r) {
      case 'admin':
        return Iconsax.shield;
      case 'lecturer':
        return Iconsax.teacher;
      default:
        return Iconsax.user;
    }
  }

  static String _roleLabel(String r) {
    switch (r) {
      case 'admin':
        return 'ADMIN';
      case 'lecturer':
        return 'LECTURER';
      default:
        return 'STUDENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.all(HomeSpacing.s20),
      decoration: BoxDecoration(
        color: HomeColors.surface1,
        borderRadius: BorderRadius.circular(HomeRadius.r24),
        border: Border.all(
          color: AppColors.stroke,
          width: HomeEffects.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: photoUrl != null && photoUrl!.isNotEmpty
                ? ClipOval(child: Image.network(photoUrl!, fit: BoxFit.cover))
                : const Icon(
                    Iconsax.user,
                    color: AppColors.primarySoft,
                    size: HomeSizes.iconLarge,
                  ),
          ),
          const Gap(HomeSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: HomeTypography.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  email,
                  style: HomeTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(HomeSpacing.s8),
                Wrap(
                  spacing: HomeSpacing.s8,
                  runSpacing: 4,
                  children: [
                    _RoleBadge(
                      icon: _roleIcon(role),
                      label: _roleLabel(role),
                      color: color,
                    ),
                    _RoleBadge(
                      icon: Iconsax.calendar,
                      label: session,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeSpacing.s8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(HomeRadius.r12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const Gap(4),
          Text(
            label,
            style: HomeTypography.caption.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// --- Stat Chip -------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HomeSpacing.s16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(HomeRadius.r20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: HomeEffects.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: HomeSizes.iconMedium),
          const Gap(HomeSpacing.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: HomeTypography.title.copyWith(color: color)),
              Text(label, style: HomeTypography.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Menu Item Model -------------------------------------------------------

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accentColor;
}

// --- Menu Tile -------------------------------------------------------------

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.accentColor ?? AppColors.primary;
    return Material(
      color: HomeColors.surface1,
      borderRadius: BorderRadius.circular(HomeRadius.r16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(HomeRadius.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeSpacing.s16,
            vertical: HomeSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeRadius.r16),
            border: Border.all(
              color: AppColors.stroke,
              width: HomeEffects.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: HomeSizes.avatar,
                height: HomeSizes.avatar,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(HomeRadius.r12),
                ),
                child: Icon(item.icon, color: color, size: HomeSizes.iconSmall),
              ),
              const Gap(HomeSpacing.s12),
              Expanded(
                child: Text(
                  item.label,
                  style: HomeTypography.body.copyWith(
                    color: item.accentColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: AppColors.textSubtle,
                size: HomeSizes.iconSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Logout Tile -----------------------------------------------------------

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.authService});

  final AuthService authService;

  static const _red = Color(0xFFFF6B6B);

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HomeColors.surface1,
        title: Text('Logout', style: HomeTypography.title),
        content: Text(
          'Are you sure you want to logout?',
          style: HomeTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: HomeTypography.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: HomeTypography.body.copyWith(color: _red),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(HomeRadius.r16),
      child: InkWell(
        onTap: () => _logout(context),
        borderRadius: BorderRadius.circular(HomeRadius.r16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeSpacing.s16,
            vertical: HomeSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeRadius.r16),
            border: Border.all(
              color: _red.withValues(alpha: 0.3),
              width: HomeEffects.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: HomeSizes.avatar,
                height: HomeSizes.avatar,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(HomeRadius.r12),
                ),
                child: const Icon(
                  Iconsax.logout,
                  color: _red,
                  size: HomeSizes.iconSmall,
                ),
              ),
              const Gap(HomeSpacing.s12),
              Text('Logout', style: HomeTypography.body.copyWith(color: _red)),
            ],
          ),
        ),
      ),
    );
  }
}
