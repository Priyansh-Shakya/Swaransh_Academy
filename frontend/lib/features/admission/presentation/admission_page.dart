import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/admission/domain/admission_prefill.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../data/admission_notifier.dart';
import 'admin_admission_page.dart';

/// The /admission nav-bar tab.
/// Admin sees submitted forms list.
/// Student/Guest sees an entry point that pushes into the funnel.
class AdmissionPage extends ConsumerWidget {
  const AdmissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);

    if (role == UserRole.admin) {
      return const AdminAdmissionPage();
    }

    // Student / Guest - entry point into the apply funnel
    final prefill = ref.watch(admissionPrefillProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admission')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, Color(0xFF2A4070)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined,
                      color: AppColors.gold, size: 36),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Join Swaransh Academy',
                    style: AppTypography.headlineLarge
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Begin your journey in music, dance, acting, or production.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                      ),
                      onPressed: () {
                        if (prefill != null) {
                          ref
                              .read(admissionFormProvider.notifier)
                              .prefill(prefill.department, prefill.subject);
                          ref
                              .read(admissionPrefillProvider.notifier)
                              .clear();
                        }
                        context.push('/admission/form');
                      },
                      child: const Text('Apply Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // What to expect
            Text('How it works', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            _Step(
              number: 1,
              title: 'Fill the Application Form',
              subtitle: 'Your personal, contact & course details.',
            ),
            _Step(
              number: 2,
              title: 'Review Terms & Conditions',
              subtitle: 'Attendance, fees, conduct and refund policy.',
            ),
            _Step(
              number: 3,
              title: 'Complete Payment',
              subtitle: 'Submit your application and await approval.',
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(
      {required this.number, required this.title, required this.subtitle});
  final int number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
