import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/students/data/provider.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

/// Feature-specific API service for students.
class StudentsApiService {
  StudentsApiService(this._apiService);

  final ApiService<Student> _apiService;

  /// Get all students with optional filters.
  Future<List<Student>> getAllStudents({
    String? department,
    String? admissionType,
    String? learningMode,
    String? feeType,
    String? batch,
    double? feesMin,
    double? feesMax,
    String? joinedAfter,
    String? joinedBefore,
    String? search,
  }) async {
    debugPrint("getAllStudents() called");
    final students = await _apiService.getAll(
      endpoint: '/studentList',
      queryParams: {
        if (department != null) 'department': department,
        if (admissionType != null) 'admission_type': admissionType,
        if (learningMode != null) 'learning_mode': learningMode,
        if (feeType != null) 'fee_type': feeType,
        if (batch != null) 'batch': batch,
        if (feesMin != null) 'fees_min': feesMin,
        if (feesMax != null) 'fees_max': feesMax,
        if (joinedAfter != null) 'joined_after': joinedAfter,
        if (joinedBefore != null) 'joined_before': joinedBefore,
        if (search != null) 'search': search,
      },
    );
    debugPrint("After Await ...");
    debugPrint("Students List: ${students.toString()}");
    return students;
  }

  /// Get a single student by ID.
  Future<Student> getStudent(int id) {
    return _apiService.getById(endpoint: '/student', id: id.toString());
  }

  /// Create a new student.
  Future<Student> createStudent(CreateStudent student) {
    final payload = Map<String, dynamic>.from(student.toJson())..remove('id');
    return _apiService.create(endpoint: '/student', data: payload);
  }

  /// Update an existing student.
  Future<Student> updateStudent(Student student) {
    return _apiService.update(
      endpoint: '/student',
      id: student.id.toString(),
      data: student.toJson(),
    );
  }

  /// Delete a student.
  Future<void> deleteStudent(int id) {
    return _apiService.delete(endpoint: '/student', id: id.toString());
  }
}

final studentsApiServiceProvider = Provider<StudentsApiService>((ref) {
  final apiService = ref.watch(studentApiServiceProvider);
  return StudentsApiService(apiService);
});
