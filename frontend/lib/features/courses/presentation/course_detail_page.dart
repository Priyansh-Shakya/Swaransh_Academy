import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/helper.dart';
import 'package:swaransh_academy/Core/sounds/player.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';

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

    final imageUrl = (course.imageUrl != null && course.imageUrl!.isNotEmpty)
        ? resolvePublicImage(
            ref,
            bucket: StorageBucket.coursePhotos,
            pathOrUrl: course.imageUrl!,
          )
        : null;

    if (isDesktop) {
      return _buildDesktopLayout(context, ref, imageUrl, deptColor);
    }

    return _buildMobileLayout(context, ref, imageUrl, deptColor);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    String? imageUrl,
    Color deptColor,
  ) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation & Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                      ),
                    ),
                    if (isAdmin)
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit Course',
                            onPressed: () =>
                                context.push('/home/course/${course.id}/edit'),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete Course',
                            onPressed: () => _confirmDelete(context, ref),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Hero Course Banner Image Card
                Container(
                  width: double.infinity,
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  deptColor.withValues(alpha: 0.85),
                                  deptColor.withValues(alpha: 0.5),
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
                                size: 84,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Details Card Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.courseName,
                          style: AppTypography.displayMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          Chip(
                            label: Text(
                                course.mapsToDepartment.replaceAll('_', ' ')),
                            backgroundColor: AppColors.ivoryDeep,
                          ),
                          Chip(
                            label: Text(course.tag),
                            backgroundColor: AppColors.ivoryDeep,
                          ),
                          Chip(
                            label: Text(course.mode),
                            backgroundColor: AppColors.ivoryDeep,
                          ),
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
                      const Divider(),
                      _InfoRow(
                        icon: Icons.currency_rupee,
                        label: 'Fees',
                        value: '\u20B9${course.fees.toStringAsFixed(0)}',
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.laptop_mac,
                        label: 'Mode',
                        value: course.mode,
                      ),
                      const Divider(),
                      _InfoRow(
                        icon: Icons.menu_book_outlined,
                        label: 'Subject',
                        value: course.mapsToSubject,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (!isAdmin)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
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
                              padding:
                                  EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Text(
                                'Apply Now',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    String? imageUrl,
    Color deptColor,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          pinned: true,
          backgroundColor: AppColors.ivory,
          foregroundColor: AppColors.navy,
          actions: isAdmin
              ? [
                  Container(
                    decoration: const BoxDecoration(
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
                    decoration: const BoxDecoration(
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
            collapseMode: CollapseMode.pin,
            background: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          deptColor.withValues(alpha: 0.85),
                          deptColor.withValues(alpha: 0.5),
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
                        color: Colors.white.withValues(alpha: 0.85),
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
              await AppSounds.playDeleteSound();
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
