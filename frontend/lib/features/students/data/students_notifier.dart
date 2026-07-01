import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';


/// MOCK repository, backed by an in-memory list. Swap each method body for
/// a real Dio call (POST /student, PUT /student/{id}, DELETE /student/{id},
/// GET /studentList) once the backend exists - method signatures and the
/// optimistic-update pattern should not need to change.
///
/// OPTIMISTIC UPDATE PATTERN: every mutation updates local state
/// immediately, then "calls the API" in the background. If that call
/// fails, the previous state is restored and the caller is responsible for
/// surfacing the error (the UI layer catches the rethrown exception and
/// shows a snackbar - see students_list_page.dart / student_detail_page.dart).
class StudentsNotifier extends AsyncNotifier<List<Student>> {
  int _nextId = 7;

  @override
  Future<List<Student>> build() async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate network
    return List.of(_seedStudents);
  }

  Future<void> addStudent(Student draft) async {
    final previous = state;
    final current = state.valueOrNull ?? [];
    final created = draft.copyWith().let((_) => Student(
          id: _nextId++,
          name: draft.name,
          admissionType: draft.admissionType,
          learningMode: draft.learningMode,
          department: draft.department,
          batch: draft.batch,
          startTime: draft.startTime,
          endTime: draft.endTime,
          subject: draft.subject,
          userId: draft.userId,
          imageUrl: draft.imageUrl,
          status: draft.status ?? 'active',
          dob: draft.dob,
          fatherName: draft.fatherName,
          gender: draft.gender,
          educationQualification: draft.educationQualification,
          contact: draft.contact,
          email: draft.email,
          address: draft.address,
          religion: draft.religion,
          caste: draft.caste,
          scholarNo: draft.scholarNo,
          dateOfJoining: draft.dateOfJoining,
          fees: draft.fees,
          feeType: draft.feeType,
          feePaidTill: draft.feePaidTill,
        ));

    // Optimistic: show it immediately.
    state = AsyncValue.data([...current, created]);

    try {
      await Future.delayed(const Duration(milliseconds: 300)); // simulate network
      // real call would go here; on success nothing further to do.
    } catch (e) {
      state = previous; // rollback
      rethrow;
    }
  }

  Future<void> updateStudent(Student updated) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data([
      for (final s in current) if (s.id == updated.id) updated else s,
    ]);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data(current.where((s) => s.id != id).toList());

    try {
      await Future.delayed(const Duration(milliseconds: 300));
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

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

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
