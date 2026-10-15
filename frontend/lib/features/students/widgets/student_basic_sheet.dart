import 'package:flutter/material.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import 'package:swaransh_academy/features/students/helper.dart';
import 'package:swaransh_academy/features/students/widgets/birthday_elements.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import '../../../../../Core/theme/staff_line_divider.dart';
import 'student_avatar.dart';

/// Shown when a student taps another student's tile. Read-only, StudentBasic
/// fields only. Modal bottom sheet keeps the context of the list visible
/// behind it, appropriate for the small amount of info shown here.
class StudentBasicSheet extends StatelessWidget {
  const StudentBasicSheet({
    super.key,
    required this.student,
    this.isBirthday = false,
  });

  final Student student;
  final bool isBirthday;

  static Future<void> show(
    BuildContext context,
    Student student, {
    bool? isBirthday,
  }) {
    final birthdayActive = isBirthday ?? hasBirthday(student);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          StudentBasicSheet(student: student, isBirthday: birthdayActive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(student.department);

    Widget sheetContent = Container(
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
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Avatar with Large Hat
          StudentAvatar(student: student, radius: 60),

          const SizedBox(height: AppSpacing.md),

          // Name + Birthday Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  student.name,
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (isBirthday) ...[
                const SizedBox(width: 8),
                const Text('🎂', style: TextStyle(fontSize: 22)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Department & Birthday Banner
          if (isBirthday) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: const Color(0xFFFFB74D), width: 1),
              ),
              child: const Text(
                '🎉 Happy Birthday! Wishing you a great year! 🎉',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          Text(
            student.department.replaceAll('_', ' '),
            style: AppTypography.bodyMedium.copyWith(color: deptColor),
          ),
          const SizedBox(height: AppSpacing.md),
          const StaffLineDivider(),
          const SizedBox(height: AppSpacing.lg),

          _InfoRow(label: 'Subject', value: student.subject),
          _InfoRow(
            label: 'Admission Type',
            value: student.admissionType.replaceAll('_', ' '),
          ),
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

    // Apply Glowing Border when it is a birthday
    if (isBirthday) {
      sheetContent = SheetGlowWrapper(child: sheetContent);
    }

    // Overlay Confetti Cannon on top of the sheet
    return Stack(
      children: [
        sheetContent,
        if (isBirthday)
          const Positioned.fill(child: ConfettiPopperBlast(particleCount: 65)),
      ],
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
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
