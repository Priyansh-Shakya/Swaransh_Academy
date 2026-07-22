import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_exceptions.dart';
import 'package:swaransh_academy/features/profile/domain/profile.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import 'package:flutter/foundation.dart';

class ProfileApiService {
  ProfileApiService(this._dio);
  final Dio _dio;

  /// Get current user's linked student profile(s).
  /// Returns 1 item for most users, N items for siblings sharing an account.
  Future<Object> getMyProfile() async {
    final response = await _dio.get('/profile/me');

    debugPrint("profile api service: Get profile function: ${response.data}");

    final body = response.data as Map<String, dynamic>;

    final type = body['type'] as String?;
    final data = body['data'];

    switch (type) {
      case 'student':
        return (data as List)
            .map((e) => Student.fromJson(e as Map<String, dynamic>))
            .toList();
      case 'user':
        return UserProfile.fromJson(data as Map<String, dynamic>);
      default:
        throw ParsingException("Unknown profile type: $type");
    }
  }

  // Family<Student> getStudentProfile(int studentId) {
  //    return _studentProfileApiService.getById(
  //      endpoint: '/profile/student',
  //      id: studentId.toString(),
  //    );
  // }
}

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileApiService(dio);
});

// /// Feature-specific API service for profiles.
// class ProfileApiService {
//   ProfileApiService(
//     this._userService,
//     this._studentProfileApiService,
//     this._dio,
//   );

//   final ApiService<UserProfile> _userService;
//   final ApiService<Student> _studentProfileApiService;
//   final Dio _dio;

//   /// Get current user's profile (resolves to student or user profile).
//   Future<dynamic> getMyProfile() async {
//     final response = await _dio.get('/profile/me');

//     debugPrint("RAW profile response: ${response.data}");
//     debugPrint(response.data.runtimeType.toString());

//     // Backend returns either UserProfile or Student
//     final data = response.data as Map<String, dynamic>;
//     if (data.containsKey('admission_type')) {
//       debugPrint("Returning Student Model");
//       return Student.fromJson(data);
//     } else {
//       debugPrint("Returning User Model");
//       return UserProfile.fromJson(data);
//     }
//   }

//   /// Get student profile by student ID (admin view).
//   Future<Student> getStudentProfile(int studentId) {
//     return _studentProfileApiService.getById(
//       endpoint: '/profile/student',
//       id: studentId.toString(),
//     );
//   }

//   /// Get user profile by user ID.
//   Future<UserProfile> getUserProfile(String userId) {
//     return _userService.getById(endpoint: '/profile/user', id: userId);
//   }
// }

// final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
//   final userProfileApiService = ref.watch(userProfileApiServiceProvider);
//   final studentProfileApiService = ref.watch(studentProfileApiServiceProvider);
//   final dio = ref.watch(dioProvider);
//   return ProfileApiService(
//     userProfileApiService,
//     studentProfileApiService,
//     dio,
//   );
// });
