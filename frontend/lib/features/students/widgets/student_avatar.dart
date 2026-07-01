import 'package:flutter/material.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_typography.dart';


class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    super.key,
    required this.student,
    this.radius = 28,
  });

  final Student student;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.departmentColor(student.department);

    if (student.imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(student.imageUrl!),
        backgroundColor: color.withOpacity(0.2),
      );
    }

    final parts = student.name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : student.name.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.18),
      child: Text(
        initials,
        style: AppTypography.titleLarge.copyWith(
          color: color,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}
