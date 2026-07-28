import 'package:flutter/material.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import '../../../../../Core/theme/staff_line_divider.dart';

import 'student_avatar.dart';

/// Shown when a student taps another student's tile. Read-only, StudentBasic
/// fields only. Modal bottom sheet keeps the context of the list visible
/// behind it, appropriate for the small amount of info shown here.
class StudentBasicSheet extends StatelessWidget {
  const StudentBasicSheet({super.key, required this.student});

  final Student student;

  static Future<void> show(BuildContext context, Student student) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudentBasicSheet(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(student.department);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StudentAvatar(student: student, radius: 50),
          const SizedBox(height: AppSpacing.md),
          Text(student.name, style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            student.department.replaceAll('_', ' '),
            style: AppTypography.bodyMedium.copyWith(color: deptColor),
          ),
          const SizedBox(height: AppSpacing.md),
          const StaffLineDivider(),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(label: 'Subject', value: student.subject),
          _InfoRow(label: 'Admission Type', value: student.admissionType.replaceAll('_', ' ')),
          _InfoRow(label: 'Learning Mode', value: student.learningMode),
          _InfoRow(label: 'Batch', value: student.batch),
          _InfoRow(
            label: 'Timing',
            value: '${student.startTime} – ${student.endTime}',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTypography.label),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
