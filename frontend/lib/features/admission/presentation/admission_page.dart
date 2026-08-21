import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../Core/auth/auth_notifier.dart';
import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../data/admission_notifier.dart';
import '../domain/admission_form_record.dart';
import 'admin_admission_page.dart';

class AdmissionPage extends ConsumerWidget {
  const AdmissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    if (role == UserRole.admin) return const AdminAdmissionPage();

    final isSignedIn = ref.watch(isSignedInProvider);
    final myFormsAsync = isSignedIn
        ? ref.watch(myAdmissionFormsProvider)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Admission')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Hero / Apply Now ----
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
                  const Icon(
                    Icons.school_outlined,
                    color: AppColors.gold,
                    size: 36,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Join Swaransh Academy',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Begin your journey in music, dance, acting, or production.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                      ),
                      onPressed: () => context.push('/admission/form'),
                      child: const Text('Apply Now'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---- How it works ----
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
              title: 'Submit Application',
              subtitle: 'Admin reviews and approves your application.',
            ),
            _Step(
              number: 4,
              title: 'Complete Payment',
              subtitle: 'Pay fees after your application is approved.',
            ),

            // ---- My Applications (signed-in users only) ----
            if (isSignedIn && myFormsAsync != null) ...[
              const SizedBox(height: AppSpacing.xl),
              const Center(child: StaffLineDivider(width: 56)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Applications', style: AppTypography.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () =>
                        ref.read(myAdmissionFormsProvider.notifier).refresh(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              myFormsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Text(
                  'Could not load applications: $e',
                  style: AppTypography.bodySmall,
                ),
                data: (forms) {
                  if (forms.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.ivoryDeep,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'You haven\'t submitted any applications yet.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: forms
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _MyApplicationCard(form: f),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _MyApplicationCard extends StatelessWidget {
  const _MyApplicationCard({required this.form});
  final AdmissionFormRecord form;

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(form.department);
    final statusColor = switch (form.status) {
      'approved' => AppColors.active,
      'declined' => AppColors.error,
      _ => AppColors.pendingPayment,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.department.replaceAll('_', ' '),
                      style: AppTypography.titleLarge,
                    ),
                    Text(form.subject, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  form.status,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Proceed to Payment — only show when Approved
          if (form.status == 'Approved') ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                ),
                onPressed: () => context.push('/admission/pay', extra: form),
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Proceed to Payment →'),
              ),
            ),
          ] else if (form.status == 'Pending') ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Under review by the academy. You\'ll be notified once approved.',
              style: AppTypography.caption,
            ),
          ] else if (form.status == 'Declined') ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your application was not approved. Contact us for more info.',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
  });
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
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
