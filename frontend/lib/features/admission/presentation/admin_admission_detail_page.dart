import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../data/admission_notifier.dart';
import '../domain/admission_form_record.dart';

class AdminAdmissionDetailPage extends ConsumerWidget {
  const AdminAdmissionDetailPage({super.key, required this.form});
  final AdmissionFormRecord form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptColor = AppColors.departmentColor(form.department);
    final isPending = form.status == 'Pending';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Application Review'),
        backgroundColor: AppColors.ivory,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, deptColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      form.name.isNotEmpty ? form.name[0].toUpperCase() : '?',
                      style: AppTypography.headlineLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(form.name,
                      style: AppTypography.headlineMedium
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  _StatusChip(status: form.status),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Course Details ----
                  _Section(
                    title: 'Course & Enrollment',
                    children: [
                      _InfoRow('Department',
                          form.department.replaceAll('_', ' ')),
                      _InfoRow('Subject', form.subject),
                      _InfoRow('Admission Type',
                          form.admissionType.replaceAll('_', ' ')),
                      _InfoRow('Learning Mode', form.learningMode),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Contact ----
                  _Section(
                    title: 'Contact Information',
                    children: [
                      _InfoRow('Email', form.email),
                      _InfoRow('Phone', form.contact),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Fees ----
                  if (form.fees != null)
                    _Section(
                      title: 'Fees',
                      children: [
                        _InfoRow('Amount',
                            '\u20B9${form.fees!.toStringAsFixed(0)}'),
                        if (form.feeType != null)
                          _InfoRow('Type',
                              form.feeType!.replaceAll('_', ' ')),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ---- Actions ----
                  if (isPending) ...[
                    const Center(child: StaffLineDivider(width: 56)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            onPressed: () =>
                                _confirm(context, ref, approve: false),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.active,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                            ),
                            onPressed: () =>
                                _confirm(context, ref, approve: true),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: form.status == 'Approved'
                            ? AppColors.active.withOpacity(0.08)
                            : AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'This application has been ${form.status.toLowerCase()}.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: form.status == 'Approved'
                              ? AppColors.active
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref,
      {required bool approve}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Application?' : 'Decline Application?'),
        content: Text(approve
            ? 'A student record will be created for ${form.name}.'
            : '${form.name}\'s application will be declined.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    approve ? AppColors.active : AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      if (approve) {
        await ref
            .read(admissionFormsListProvider.notifier)
            .approve(form.id);
      } else {
        await ref
            .read(admissionFormsListProvider.notifier)
            .decline(form.id);
      }
      if (context.mounted) context.pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${approve ? 'approve' : 'decline'}')),
        );
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                AppTypography.titleLarge.copyWith(color: AppColors.gold)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTypography.label),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Approved' => AppColors.active,
      'Declined' => AppColors.error,
      _ => AppColors.pendingPayment,
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: AppTypography.caption
            .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
