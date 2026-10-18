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
    final isSignedIn = ref.watch(isSignedInProvider);
    debugPrint("ROLE SELECT PAGE: isSignedIn = $isSignedIn");
    if (isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/home');
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Fall back to a sensible minimum height if screen is too cramped
            // so the logo doesn't shrink to zero and calculations stay stable.
            final effectiveHeight = constraints.maxHeight < 620
                ? 620.0
                : constraints.maxHeight;

            final logoSize = (effectiveHeight * 0.30).clamp(120.0, 220.0);

            const cardGap = AppSpacing.md;
            const cardHeight = 48.0 + (AppSpacing.md * 2);
            const cardsHeight = (cardHeight * 3) + (cardGap * 2);

            final fixedHeight =
                logoSize +
                4 +
                48 +
                AppSpacing.md +
                20 +
                AppSpacing.md +
                cardsHeight +
                20;

            final remaining = effectiveHeight - fixedHeight;
            final sectionGap = (remaining / 5).clamp(12.0, 28.0);

            final topGap = sectionGap * 0.6;
            final logoTextGap = sectionGap * 0.45;
            final dividerGap = sectionGap * 0.55;
            final footerGap = sectionGap * 0.65;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),

                        Image.asset(
                          'assets/app_logo.png',
                          width: logoSize,
                          height: logoSize,
                        ),

                        SizedBox(height: logoTextGap),

                        Text(
                          'Swaransh Academy',
                          style: AppTypography.headlineLarge,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'How would you like to continue?',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: dividerGap),

                        const StaffLineDivider(width: 56),

                        SizedBox(height: dividerGap),

                        _RoleCard(
                          icon: Icons.explore_outlined,
                          iconColor: AppColors.deptActing,
                          title: 'Explore as Guest',
                          subtitle:
                              'Browse courses and academy info without signing in.',
                          onTap: () => context.go('/home'),
                        ),

                        const SizedBox(height: cardGap),

                        _RoleCard(
                          icon: Icons.school_outlined,
                          iconColor: AppColors.gold,
                          title: "I'm a Student",
                          subtitle:
                              'Sign in to view your profile, fees, and fellow students.',
                          onTap: () {
                            ref.read(selectedRoleProvider.notifier).state =
                                UserRole.student;
                            context.push('/auth');
                          },
                        ),

                        const SizedBox(height: cardGap),

                        _RoleCard(
                          icon: Icons.admin_panel_settings_outlined,
                          iconColor: AppColors.navy,
                          title: 'Admin Access',
                          subtitle:
                              'Manage students, admissions, and academy settings.',
                          onTap: () {
                            ref.read(selectedRoleProvider.notifier).state =
                                UserRole.admin;
                            context.push('/auth');
                          },
                        ),

                        SizedBox(height: footerGap),

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
              ),
            );
          },
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
                width: 48,
                height: 48,
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
