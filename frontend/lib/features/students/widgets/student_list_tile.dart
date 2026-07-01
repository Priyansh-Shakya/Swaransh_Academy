import 'package:flutter/material.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import 'student_avatar.dart';

class StudentListTile extends StatelessWidget {
  const StudentListTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(student.department);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StudentAvatar(student: student, radius: 30),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary: name + status dot for admin
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: AppTypography.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.status != null)
                          _StatusDot(status: student.status!),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Secondary: department · subject
                    Text(
                      '${student.department.replaceAll('_', ' ')} · ${student.subject}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Tertiary: batch + timing chips
                    Row(
                      children: [
                        _Chip(label: student.batch, color: deptColor),
                        const SizedBox(width: AppSpacing.xs),
                        _Chip(
                          label: '${student.startTime} – ${student.endTime}',
                          color: AppColors.navy,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
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

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.active,
      'pending_payment' => AppColors.pendingPayment,
      _ => AppColors.inactive,
    };
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
