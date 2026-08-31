import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/helper.dart';
import 'package:swaransh_academy/Core/sounds/player.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';

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
    final isPending = form.status == 'pending';

    debugPrint("From admin admission page: ${form.gender}");

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
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, deptColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo — big, fills available height, rounded rect
                  Expanded(
                    flex: 4,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: deptColor.withOpacity(0.15),
                          backgroundImage: form.imageUrl.isNotEmpty
                              ? NetworkImage(
                                  resolvePublicImage(
                                    ref,
                                    bucket: StorageBucket.admissionPhotos,
                                    pathOrUrl: form.imageUrl,
                                  ),
                                )
                              : null,
                          child: form.imageUrl.isEmpty
                              ? Text(
                                  form.name.isNotEmpty
                                      ? form.name[0].toUpperCase()
                                      : '?',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: deptColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Name + status + quick details on the right
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StatusChip(status: form.status),
                        const SizedBox(height: AppSpacing.md),

                        // Quick metadata facts
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 6,
                          children: [
                            if (form.gender?.isNotEmpty == true)
                              _MiniDetail(
                                icon: Icons.person_outline,
                                label: form.gender!,
                              ),
                            if (form.dob != null)
                              _MiniDetail(
                                icon: Icons.cake_outlined,
                                label: _formatDate(form.dob!),
                              ),
                            if (form.batch?.isNotEmpty == true)
                              _MiniDetail(
                                icon: Icons.groups_2_outlined,
                                label: form.batch!,
                              ),
                            if (form.startTime?.isNotEmpty == true &&
                                form.endTime?.isNotEmpty == true)
                              _MiniDetail(
                                icon: Icons.schedule_outlined,
                                label: _formatTimeRange(
                                  form.startTime!,
                                  form.endTime!,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Personal Details ----
                  _Section(
                    title: 'Personal Details',
                    children: [
                      if (form.fatherName != null &&
                          form.fatherName!.isNotEmpty)
                        _InfoRow("Father's Name", form.fatherName!),
                      if (form.dob != null)
                        _InfoRow('Date of Birth', _formatDate(form.dob!)),
                      if (form.gender != null && form.gender!.isNotEmpty)
                        _InfoRow('Gender', form.gender!),
                      if (form.religion != null && form.religion!.isNotEmpty)
                        _InfoRow('Religion', form.religion!),
                      if (form.caste != null && form.caste!.isNotEmpty)
                        _InfoRow('Caste / Category', form.caste!),
                      if (form.address != null && form.address!.isNotEmpty)
                        _InfoRow('Address', form.address!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Course & Enrollment ----
                  _Section(
                    title: 'Course & Enrollment',
                    children: [
                      _InfoRow(
                        'Department',
                        form.department.replaceAll('_', ' '),
                      ),
                      _InfoRow('Subject', form.subject),
                      _InfoRow(
                        'Admission Type',
                        form.admissionType.replaceAll('_', ' '),
                      ),
                      _InfoRow('Learning Mode', form.learningMode),
                      if (form.batch != null && form.batch!.isNotEmpty)
                        _InfoRow('Batch', form.batch!),
                      if (form.startTime != null &&
                          form.endTime != null &&
                          form.startTime!.isNotEmpty &&
                          form.endTime!.isNotEmpty)
                        _InfoRow(
                          'Timing',
                          _formatTimeRange(form.startTime, form.endTime),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---- Academic Background ----
                  if (form.educationQualification != null &&
                      form.educationQualification!.isNotEmpty) ...[
                    _Section(
                      title: 'Academic Background',
                      children: [
                        _InfoRow('Qualification', form.educationQualification!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ---- Contact Information ----
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
                        _InfoRow(
                          'Amount',
                          '\u20B9${form.fees!.toStringAsFixed(0)}',
                        ),
                        if (form.feeType != null)
                          _InfoRow('Type', form.feeType!.replaceAll('_', ' ')),
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
                                vertical: AppSpacing.md,
                              ),
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
                                vertical: AppSpacing.md,
                              ),
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
                        color: form.status.toLowerCase() == 'approved'
                            ? AppColors.active.withOpacity(0.08)
                            : AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'This application has been ${form.status.toLowerCase()}.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: form.status.toLowerCase() == 'approved'
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

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Application?' : 'Decline Application?'),
        content: Text(
          approve
              ? 'A student record will be created for ${form.name}.'
              : '${form.name}\'s application will be declined.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.active : AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx, true);
              if (approve) {
                await AppSounds.playApproveSound();
              } else {
                await AppSounds.playDeclineSound();
              }
            },
            child: Text(approve ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      if (approve) {
        await ref.read(admissionFormsListProvider.notifier).approve(form.id);
      } else {
        await ref.read(admissionFormsListProvider.notifier).decline(form.id);
      }
      if (context.mounted) context.pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${approve ? 'approve' : 'decline'}'),
          ),
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
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(color: AppColors.gold),
        ),
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
          SizedBox(width: 130, child: Text(label, style: AppTypography.label)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniDetail extends StatelessWidget {
  const _MiniDetail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Converts "HH:mm:ss" or "HH:mm" (24h) -> "h:mm AM/PM"
String _to12Hour(String time24) {
  final parts = time24.split(':');
  if (parts.length < 2) return time24;
  final hour24 = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1].padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  int hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:$minute $period';
}

String _formatTimeRange(String? start, String? end) {
  if (start == null || end == null) return '—';
  return '${_to12Hour(start)} - ${_to12Hour(end)}';
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
