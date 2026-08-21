import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/courses/data/courses_api_service.dart';

import '../domain/course.dart';

/// Repository layer for course CRUD using the shared ApiService.
class CoursesNotifier extends AsyncNotifier<List<Course>> {
  @override
  Future<List<Course>> build() async {
    return ref.read(coursesApiServiceProvider).getAllCourses();
  }

  Future<void> refreshList() async {
    state = AsyncValue.loading();
    final data = await ref.read(coursesApiServiceProvider).getAllCourses();
    state = AsyncValue.data(data);
  }

  Future<void> addCourse(Course draft) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    try {
      final created = await ref
          .read(coursesApiServiceProvider)
          .createCourse(draft);
      state = AsyncValue.data([...current, created]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCourse(Course updated) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    try {
      final updatedCourse = await ref
          .read(coursesApiServiceProvider)
          .updateCourse(updated);
      state = AsyncValue.data([
        for (final c in current)
          if (c.id == updatedCourse.id) updatedCourse else c,
      ]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCourse(int id) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    try {
      await ref.read(coursesApiServiceProvider).deleteCourse(id);
      state = AsyncValue.data(current.where((c) => c.id != id).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Course? findById(int id) {
    final current = state.valueOrNull ?? [];
    for (final c in current) {
      if (c.id == id) return c;
    }
    return null;
  }
}

final coursesProvider = AsyncNotifierProvider<CoursesNotifier, List<Course>>(
  CoursesNotifier.new,
);
