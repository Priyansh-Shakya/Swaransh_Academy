import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';

import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../navigation/presentation/app_shell.dart';
import '../data/courses_repository.dart';
import 'widgets/course_card.dart';

class CoursesPage extends ConsumerWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);
    final role = ref.watch(currentRoleProvider);
    final isAdmin = role == UserRole.admin;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= kRailBreakpoint;

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),

      //! Add course button
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/home/course/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textOnGold,
            )
          : null,
      //! FAB at left
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: coursesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, _) => Center(child: Text('Could not load courses: $err')),
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No courses yet'));
          }

          if (isWide) {
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.82,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  imageHeight: 140,
                  onTap: () => _openDetail(context, course.id),
                );
              },
            );
          }

          // Android: big cards, ~2 visible on screen at once. Achieved by
          // sizing each card's image to a fraction of available height
          // rather than hardcoding a pixel value, so it adapts across
          // different phone screen sizes instead of only working on one.
          final availableHeight =
              MediaQuery.sizeOf(context).height -
              kToolbarHeight -
              MediaQuery.paddingOf(context).top;
          final cardImageHeight = (availableHeight / 2) * 0.55;

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final course = courses[index];
              return CourseCard(
                course: course,
                imageHeight: cardImageHeight.clamp(130, 220),
                onTap: () => _openDetail(context, course.id),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, int courseId) {
    context.push('/home/course/$courseId');
  }
}
