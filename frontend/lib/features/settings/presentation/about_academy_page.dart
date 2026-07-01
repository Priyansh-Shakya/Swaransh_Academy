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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---- Academy hero ----
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            title: const Text('About Us'),
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
                              width: 80,
                              height: 80,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo or initials
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.gold.withOpacity(0.15),
              backgroundImage: member.photoUrl != null
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null
                  ? Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.gold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: AppTypography.titleLarge),
                  Text(
                    member.position,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(member.bio, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
