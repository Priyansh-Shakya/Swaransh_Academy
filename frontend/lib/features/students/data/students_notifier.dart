import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/students/data/students_api_service.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

/// Uses real API calls (POST /student, PUT /student/{id}, DELETE /student/{id},
/// GET /studentList).
///
/// OPTIMISTIC UPDATE PATTERN: every mutation updates local state
/// immediately, then "calls the API" in the background. If that call
/// fails, the previous state is restored and the caller is responsible for
/// surfacing the error (the UI layer catches the rethrown exception and
/// shows a snackbar - see students_list_page.dart / student_detail_page.dart).
class StudentsNotifier extends AsyncNotifier<List<Student>> {
  @override
  Future<List<Student>> build() async {
    final students = await ref
        .read(studentsApiServiceProvider)
        .getAllStudents();

    debugPrint("Students List: $students");
    return students;
  }

  Future<void> refreshList() async {
    state = AsyncValue.loading();
    final data = await ref.read(studentsApiServiceProvider).getAllStudents();
    state = AsyncValue.data(data);
  }

  Future<void> addStudent(CreateStudent draft) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = const AsyncValue.loading();

    try {
      final created = await ref
          .read(studentsApiServiceProvider)
          .createStudent(draft);
      state = AsyncValue.data([...current, created]);
    } catch (e) {
      debugPrint("Error Creating Student from Notifier: $e");
      state = previous;
      rethrow;
    }
  }

  Future<void> updateStudent(Student updated) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data([
      for (final s in current)
        if (s.id == updated.id) updated else s,
    ]);

    try {
      await ref.read(studentsApiServiceProvider).updateStudent(updated);
    } catch (e) {
      debugPrint("Error from student notifier (UPDATE STUDENT): $e");
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data(current.where((s) => s.id != id).toList());

    try {
      await ref.read(studentsApiServiceProvider).deleteStudent(id);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Student? findById(int id) {
    final current = state.valueOrNull ?? [];
    for (final s in current) {
      if (s.id == id) return s;
    }
    return null;
  }
}

final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<Student>>(
  StudentsNotifier.new,
);
