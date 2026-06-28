import 'package:flutter/material.dart';
import '../../../../Core/theme/app_colors.dart';
import '../../../../Core/theme/app_spacing.dart';
import '../../../../Core/theme/app_typography.dart';
import '../../domain/course.dart';

/// Big card: image, title, department/tag chips, fee, duration, mode.
/// On Android this is sized so roughly 2 fit on screen at once (per
/// reference: food-delivery/shopping app product cards) - achieved via a
/// fixed image height rather than a fixed card height, so text never gets
/// clipped on smaller phones.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.imageHeight = 160,
  });

  final Course course;
  final VoidCallback onTap;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(course.mapsToDepartment);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseImage(course: course, height: imageHeight, deptColor: deptColor),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    style: AppTypography.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Tag(label: course.mapsToDepartment.replaceAll('_', ' '), color: deptColor),
                      _Tag(label: course.tag, color: AppColors.gold),
                      _Tag(label: course.mode, color: AppColors.navy),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(course.duration, style: AppTypography.bodySmall),
                        ],
                      ),
                      Text(
                        '\u20B9${course.fees.toStringAsFixed(0)}',
                        style: AppTypography.titleLarge.copyWith(color: AppColors.navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.course, required this.height, required this.deptColor});

  final Course course;
  final double height;
  final Color deptColor;

  @override
  Widget build(BuildContext context) {
    if (course.imageUrl != null) {
      return Image.network(
        course.imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    // No image yet from backend - a colored gradient block keyed to the
    // department accent, with a representative icon, rather than a blank
    // grey box. Keeps cards visually distinct even pre-photography.
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [deptColor.withOpacity(0.85), deptColor.withOpacity(0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          course.tag == 'Vocal' ? Icons.mic_none : Icons.music_note,
          size: 48,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
