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

// Mock data kept for reference/testing, not used in build()
final List<Student> _seedStudents = [
  const Student(
    id: 1,
    name: 'Aarav Sharma',
    admissionType: 'Regular',
    learningMode: 'Offline',
    department: 'Music',
    batch: 'Morning',
    startTime: '08:00',
    endTime: '09:00',
    subject: 'Guitar',
    status: 'active',
    gender: 'male',
    contact: '9876543210',
    email: 'aarav.sharma@gmail.com',
    fatherName: 'Rajesh Sharma',
    educationQualification: 'High_School',
    address: 'Bhopal, MP',
    scholarNo: 'SW-2024-001',
    dateOfJoining: '2024-06-01',
    fees: 2500,
    feeType: 'Monthly',
    feePaidTill: '2026-06-30',
  ),
  const Student(
    id: 2,
    name: 'Diya Patel',
    admissionType: 'Regular',
    learningMode: 'Hybrid',
    department: 'Dance',
    batch: 'Evening',
    startTime: '17:00',
    endTime: '18:00',
    subject: 'Kathak',
    status: 'active',
    gender: 'female',
    contact: '9876500000',
    email: 'diya.patel@gmail.com',
    fatherName: 'Manish Patel',
    educationQualification: 'Bachelors',
    address: 'Bhopal, MP',
    scholarNo: 'SW-2024-002',
    dateOfJoining: '2024-08-15',
    fees: 2200,
    feeType: 'Quarterly',
    feePaidTill: '2026-09-15',
  ),
  const Student(
    id: 3,
    name: 'Kabir Singh',
    admissionType: 'Band_Training',
    learningMode: 'Offline',
    department: 'Music',
    batch: 'Evening',
    startTime: '18:00',
    endTime: '19:00',
    subject: 'Tabla',
    status: 'pending_payment',
    gender: 'male',
    contact: null,
    email: null,
    fatherName: 'Harpreet Singh',
    educationQualification: 'Primary_School',
    address: 'Bhopal, MP',
    scholarNo: null,
    dateOfJoining: null,
    fees: 1800,
    feeType: 'Monthly',
    feePaidTill: null,
  ),
];
