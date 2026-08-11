import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_typography.dart';

class StudentAvatar extends ConsumerWidget {
  const StudentAvatar({super.key, required this.student, this.radius = 28});

  final Student student;
  final double radius;

  String _initials() {
    final parts = student.name.trim().split(' ');
    return parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : student.name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.departmentColor(student.department);
    final path = student.imageUrl;

    Widget fallback() => CircleAvatar(
      radius: radius,
      backgroundColor: color.withOpacity(0.18),
      child: Text(
        _initials(),
        style: AppTypography.titleLarge.copyWith(
          color: color,
          fontSize: radius * 0.65,
        ),
      ),
    );

    if (path == null || path.isEmpty) return fallback();

    return FutureBuilder<String>(
      future: ref
          .read(supabaseStorageServiceProvider)
          .getSignedUrl(bucket: StorageBucket.studentPhotos, path: path),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return fallback(); // loading or error -> initials, never broken image
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(snapshot.data!),
        );
      },
    );
  }
}
