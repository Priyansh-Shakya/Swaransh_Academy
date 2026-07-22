import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/local_storage/shared_pref.dart';
import 'package:swaransh_academy/features/profile/data/profile_api_service.dart';
import 'package:swaransh_academy/features/profile/domain/profile.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

//* This class Resolves which profile we are getting -> User or Student , Also checks lenght of student records to determine if we need to show scholar number dailog.
class ProfileResult {
  final List<Student>? students;
  final UserProfile? userProfile;
  final int? totalSiblingCount;

  ProfileResult.students(this.students, {int? totalCount})
    : userProfile = null,
      totalSiblingCount = totalCount ?? students?.length ?? 0;

  ProfileResult.user(this.userProfile)
    : students = null,
      totalSiblingCount = null;

  bool get needsSelection => (students?.length ?? 0) > 1;
  bool get isStudent => students != null;
  bool get hasSiblings => (totalSiblingCount ?? 0) > 1;
}

/// Notifier for managing user profile via real API.
class ProfileNotifier extends AsyncNotifier<ProfileResult> {
  @override
  Future<ProfileResult> build() => _fetchProfile();

  Future<ProfileResult> _fetchProfile() async {
    final raw = await ref.read(profileApiServiceProvider).getMyProfile();
    debugPrint("Notifier fetch profile function: ${raw.toString()}");
    if (raw is List<Student>) {
      if (raw.length == 1) return ProfileResult.students(raw);

      final savedId = await LocalStoragePref.getSiblingStudentId();
      debugPrint("Saved Student ID in shared pref: $savedId");
      final match = raw.where((s) => s.id == savedId).firstOrNull;

      // if a saved match exists, narrow to just that one so needsSelection == false
      return ProfileResult.students(match != null ? [match] : raw);
    }

    return ProfileResult.user(raw as UserProfile);
  }

  Future<void> selectStudent(int studentId, List<Student> candidates) async {
    // TODO: await LocalStorage.setSelectedStudentId(studentId);
    final selected = candidates.firstWhere((s) => s.id == studentId);
    state = AsyncValue.data(ProfileResult.students([selected]));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchProfile);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileResult>(
  ProfileNotifier.new,
);
