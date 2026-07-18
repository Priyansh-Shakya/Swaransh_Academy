import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/profile/data/profile_api_service.dart';

/// Notifier for managing user profile via real API.
class ProfileNotifier extends AsyncNotifier<dynamic> {
  @override
  Future<dynamic> build() async {
    //! loadMyProfile();
  }

  /// Load the current user's profile (resolves to student or user profile).
  Future<void> loadMyProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(profileApiServiceProvider)
          .getMyProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load a student's profile by student ID (admin view).
  Future<void> loadStudentProfile(int studentId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(profileApiServiceProvider)
          .getStudentProfile(studentId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load a user's profile by user ID.
  Future<void> loadUserProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(profileApiServiceProvider)
          .getUserProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, dynamic>(
  ProfileNotifier.new,
);
