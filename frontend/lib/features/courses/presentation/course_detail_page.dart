import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';

import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../../admission/domain/admission_prefill.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';

class CourseDetailPage extends ConsumerWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final role = ref.watch(currentRoleProvider);
    final isAdmin = role == UserRole.admin;

    return Scaffold(
      body: coursesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, _) => Center(child: Text('Could not load course: $err')),
        data: (courses) {
          final course = courses.where((c) => c.id == courseId).firstOrNull;
          if (course == null) {
            return const Center(child: Text('Course not found'));
          }
          return _CourseDetailBody(course: course, isAdmin: isAdmin);
        },
      ),
    );
  }
}

class _CourseDetailBody extends ConsumerWidget {
  const _CourseDetailBody({required this.course, required this.isAdmin});

  final Course course;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptColor = AppColors.departmentColor(course.mapsToDepartment);

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    final imageHeight = isDesktop ? 500.0 : 220.0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: imageHeight,
          pinned: true,
          backgroundColor: AppColors.ivory,
          foregroundColor: AppColors.navy,
          actions: isAdmin
              ? [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          context.push('/home/course/${course.id}/edit'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ),
                ]
              : null,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode
                .pin, // image stays put, doesn't parallax-shift while collapsing
            background: course.imageUrl != null
                ? Image.network(
                    course.imageUrl!,
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          deptColor.withOpacity(0.85),
                          deptColor.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        course.tag == 'Vocal'
                            ? Icons.mic_none
                            : Icons.music_note,
                        size: 72,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(course.courseName, style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  Chip(
                    label: Text(course.mapsToDepartment.replaceAll('_', ' ')),
                  ),
                  Chip(label: Text(course.tag)),
                  Chip(label: Text(course.mode)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const StaffLineDivider(),
              const SizedBox(height: AppSpacing.lg),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Duration',
                value: course.duration,
              ),
              _InfoRow(
                icon: Icons.currency_rupee,
                label: 'Fees',
                value: '\u20B9${course.fees.toStringAsFixed(0)}',
              ),
              _InfoRow(
                icon: Icons.laptop_mac,
                label: 'Mode',
                value: course.mode,
              ),
              _InfoRow(
                icon: Icons.menu_book_outlined,
                label: 'Subject',
                value: course.mapsToSubject,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (!isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      debugPrint(
                        "Prefilling datra: department: ${course.mapsToDepartment}",
                      );
                      ref
                          .read(admissionPrefillProvider.notifier)
                          .set(
                            AdmissionPrefill(
                              department: course.mapsToDepartment,
                              subject: course.mapsToSubject,
                              fees: course.fees,
                            ),
                          );
                      context.go('/admission');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Text('Apply Now'),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this course?'),
        content: Text(
          '"${course.courseName}" will be removed from the catalogue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (context.mounted) context.pop();
              await ref.read(coursesProvider.notifier).deleteCourse(course.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
