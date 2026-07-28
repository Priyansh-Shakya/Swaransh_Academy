import 'package:flutter/material.dart';
import 'package:swaransh_academy/features/settings/presentation/academy_content.dart';

import '../../../../Core/theme/app_colors.dart';
import '../../../../Core/theme/app_spacing.dart';
import '../../../../Core/theme/app_typography.dart';
import '../../../../Core/theme/staff_line_divider.dart';

class AboutAcademyPage extends StatelessWidget {
  const AboutAcademyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- Academy hero ----
          SliverAppBar(
            expandedHeight: isDesktop ? 525 : 220,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            title: Text(
              'About Us',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.ivoryDeep,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: AcademyContent.academyImageUrl != null
                  ? Image.network(
                      AcademyContent.academyImageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.navy, AppColors.navyDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/app_logo.png',
                              width: 100,
                              height: 100,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                size: 56,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Academy name + tagline
                Text(AcademyContent.name, style: AppTypography.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  AcademyContent.tagline,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Center(child: StaffLineDivider(width: 56)),
                const SizedBox(height: AppSpacing.lg),

                // About text
                Text(
                  AcademyContent.about.trim(),
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Team section
                Text(
                  'The People Behind It',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                ...AcademyContent.team.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _TeamCard(member: member),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.member});
  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            CircleAvatar(
              radius: 75, // 2.5x-3x larger than before
              backgroundColor: AppColors.gold.withOpacity(0.15),
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              member.name,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              member.position,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              member.bio,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
