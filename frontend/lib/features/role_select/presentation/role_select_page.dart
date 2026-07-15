import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/role_select/presentation/selectedRoleprovider.dart';
import '../../../Core/auth/auth_notifier.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';

class RoleSelectPage extends ConsumerWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If already authenticated, skip straight to home.
    final isSignedIn = ref.watch(isSignedInProvider);
    if (isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Image.asset(
                'assets/app_logo.png',
                width: 88,
                height: 88,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.music_note, size: 64, color: AppColors.gold),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Swaransh Academy',
                  style: AppTypography.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                'How would you like to continue?',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              const StaffLineDivider(width: 56),
              const SizedBox(height: AppSpacing.xl),

              _RoleCard(
                icon: Icons.explore_outlined,
                iconColor: AppColors.deptActing,
                title: 'Explore as Guest',
                subtitle: 'Browse courses and academy info without signing in.',
                onTap: () => context.go('/home'),
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.school_outlined,
                iconColor: AppColors.gold,
                title: "I'm a Student",
                subtitle: 'Sign in to view your profile, fees, and fellow students.',
                onTap: () {
                  ref.read(selectedRoleProvider.notifier).state = UserRole.student;
                  context.push('/auth');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _RoleCard(
                icon: Icons.admin_panel_settings_outlined,
                iconColor: AppColors.navy,
                title: 'Admin Access',
                subtitle: 'Manage students, admissions, and academy settings.',
                onTap: () {
                  ref.read(selectedRoleProvider.notifier).state = UserRole.admin;
                  context.push('/auth');
                },
              ),

              const Spacer(),
              Text(
                'Your role is verified automatically after sign-in.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}



