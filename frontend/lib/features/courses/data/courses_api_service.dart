import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/courses/domain/course.dart';

import 'provider.dart';

class CoursesApiService {
  CoursesApiService(this._apiService);

  final ApiService<Course> _apiService;

  Future<List<Course>> getAllCourses({Map<String, dynamic>? queryParams}) {
    final courses = _apiService.getAll(
      endpoint: '/courseList',
      queryParams: queryParams,
    );
    debugPrint("Courses List: ${courses.toString()}");
    return courses;
  }

  Future<Course> getCourse(int id) {
    return _apiService.getById(endpoint: '/course', id: id.toString());
  }

  Future<Course> createCourse(Course course) {
    final payload = Map<String, dynamic>.from(course.toJson())..remove('id');
    return _apiService.create(endpoint: '/course', data: payload);
  }

  Future<Course> updateCourse(Course course) {
    return _apiService.update(
      endpoint: '/course',
      id: course.id.toString(),
      data: course.toJson(),
    );
  }

  Future<void> deleteCourse(int id) {
    return _apiService.delete(endpoint: '/course', id: id.toString());
  }
}

final coursesApiServiceProvider = Provider<CoursesApiService>((ref) {
  final apiService = ref.watch(courseApiServiceProvider);
  return CoursesApiService(apiService);
});
