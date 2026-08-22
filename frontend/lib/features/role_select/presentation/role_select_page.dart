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
            final h = constraints.maxHeight;

            // ----------------------------------------------------------
            // Logo
            // ----------------------------------------------------------

            final logoSize = h * 0.30;

            // ----------------------------------------------------------
            // Fixed vertical pieces
            // ----------------------------------------------------------

            const cardGap = AppSpacing.md;

            // Estimate the natural height of each RoleCard.
            //
            // Padding top + bottom = 2 * md
            // Icon = 48
            //
            // The text is comfortably below 48, so the card height
            // is essentially 48 + vertical padding.
            const cardHeight = 48.0 + (AppSpacing.md * 2);

            const cardsHeight = (cardHeight * 3) + (cardGap * 2);

            // Everything except the flexible gaps.
            final fixedHeight =
                logoSize +
                4 + // title/subtitle internal spacing
                48 + // approximate title + subtitle block
                AppSpacing.md + // divider section
                20 + // divider
                AppSpacing.md +
                cardsHeight +
                20; // footer

            // Remaining space gets distributed between the important
            // visual sections.
            final remaining = h - fixedHeight;

            // On large screens, let the layout breathe.
            //
            // On smaller screens, compress the gaps rather than
            // shrinking the logo aggressively.
            final sectionGap = (remaining / 5).clamp(6.0, 28.0);

            final topGap = sectionGap * 0.6;
            final logoTextGap = sectionGap * 0.45;
            final dividerGap = sectionGap * 0.55;
            final footerGap = sectionGap * 0.65;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(height: topGap),

                  // --------------------------------------------------
                  // LOGO
                  // --------------------------------------------------
                  Image.asset(
                    'assets/app_logo.png',
                    width: logoSize,
                    height: logoSize,
                  ),

                  SizedBox(height: logoTextGap),

                  // --------------------------------------------------
                  // TITLE
                  // --------------------------------------------------
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

                  // --------------------------------------------------
                  // ROLE CARDS
                  // --------------------------------------------------
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

                  // --------------------------------------------------
                  // FOOTER
                  // --------------------------------------------------
                  SizedBox(height: footerGap),

                  Text(
                    'Your role is verified automatically after sign-in.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),
                ],
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
