import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/profile/data/provider.dart';
import 'package:swaransh_academy/features/profile/domain/profile.dart';

/// Feature-specific API service for profiles.
class ProfileApiService {
  ProfileApiService(
    this._userProfileApiService,
    this._studentProfileApiService,
    this._dio,
  );

  final ApiService<UserProfile> _userProfileApiService;
  final ApiService<StudentProfileFull> _studentProfileApiService;
  final Dio _dio;

  /// Get current user's profile (resolves to student or user profile).
  Future<dynamic> getMyProfile(String userId) async {
    final response = await _dio.get(
      '/profile/me',
      queryParameters: {'user_id': userId},
    );
    // Backend returns either UserProfile or StudentProfileFull
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('student_id')) {
      return StudentProfileFull.fromJson(data);
    } else {
      return UserProfile.fromJson(data);
    }
  }

  /// Get student profile by student ID (admin view).
  Future<StudentProfileFull> getStudentProfile(int studentId) {
    return _studentProfileApiService.getById(
      endpoint: '/profile/student',
      id: studentId.toString(),
    );
  }

  /// Get user profile by user ID.
  Future<UserProfile> getUserProfile(String userId) {
    return _userProfileApiService.getById(
      endpoint: '/profile/user',
      id: userId,
    );
  }
}

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  final userProfileApiService = ref.watch(userProfileApiServiceProvider);
  final studentProfileApiService = ref.watch(studentProfileApiServiceProvider);
  final dio = ref.watch(dioProvider);
  return ProfileApiService(
    userProfileApiService,
    studentProfileApiService,
    dio,
  );
});
