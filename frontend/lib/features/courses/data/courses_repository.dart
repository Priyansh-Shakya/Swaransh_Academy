import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/course.dart';

/// MOCK repository, backed by an in-memory list. Swap each method body for
/// a real Dio call (POST /course, PUT /course/{id}, DELETE /course/{id},
/// GET /courseList) once the backend exists - keep the method signatures
/// the same so the UI layer never needs to change.
class CoursesNotifier extends AsyncNotifier<List<Course>> {
  int _nextId = 7;

  @override
  Future<List<Course>> build() async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate network
    return List.of(_seedCourses);
  }

  /// `draft` carries everything except a real id (caller passes id: 0,
  /// it's ignored/replaced here - mirrors how CourseCreate has no id field
  /// in the contract).
  Future<void> addCourse(Course draft) async {
    final current = state.valueOrNull ?? [];
    final created = Course(
      id: _nextId++,
      courseName: draft.courseName,
      duration: draft.duration,
      fees: draft.fees,
      mode: draft.mode,
      tag: draft.tag,
      mapsToDepartment: draft.mapsToDepartment,
      mapsToSubject: draft.mapsToSubject,
      imageUrl: draft.imageUrl,
    );
    state = AsyncValue.data([...current, created]);
  }

  Future<void> updateCourse(Course updated) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final c in current) if (c.id == updated.id) updated else c,
    ]);
  }

  Future<void> deleteCourse(int id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
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

final List<Course> _seedCourses = [
  const Course(
    id: 1,
    courseName: 'Beginner Guitar Workshop',
    duration: '3 months',
    fees: 2500,
    mode: 'Offline',
    tag: 'Instrumental',
    mapsToDepartment: 'Music',
    mapsToSubject: 'Guitar',
  ),
  const Course(
    id: 2,
    courseName: 'Classical Vocal Foundations',
    duration: '6 months',
    fees: 3000,
    mode: 'Hybrid',
    tag: 'Vocal',
    mapsToDepartment: 'Music',
    mapsToSubject: 'Vocal',
  ),
  const Course(
    id: 3,
    courseName: 'Kathak Dance - Beginner Batch',
    duration: '4 months',
    fees: 2200,
    mode: 'Offline',
    tag: 'Instrumental',
    mapsToDepartment: 'Dance',
    mapsToSubject: 'Kathak',
  ),
  const Course(
    id: 4,
    courseName: 'Tabla Rhythms Intensive',
    duration: '2 months',
    fees: 1800,
    mode: 'Offline',
    tag: 'Instrumental',
    mapsToDepartment: 'Music',
    mapsToSubject: 'Tabla',
  ),
  const Course(
    id: 5,
    courseName: 'Acting & Stagecraft Basics',
    duration: '3 months',
    fees: 2000,
    mode: 'Offline',
    tag: 'Vocal',
    mapsToDepartment: 'Acting',
    mapsToSubject: 'Acting',
  ),
  const Course(
    id: 6,
    courseName: 'Home Recording & Mixing',
    duration: '2 months',
    fees: 3500,
    mode: 'Hybrid',
    tag: 'Instrumental',
    mapsToDepartment: 'Music_Video_Production',
    mapsToSubject: 'Audio Production',
  ),
];
