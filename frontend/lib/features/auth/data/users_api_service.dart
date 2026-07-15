import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/auth/user_role.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/auth/data/provider.dart';
import 'package:swaransh_academy/features/auth/domain/user.dart';

/// Feature-specific API service for users.
class UsersApiService {
  UsersApiService(this._apiService);

  final ApiService<User> _apiService;

  /// Get user by ID.
  Future<User> getUser(String id) {
    return _apiService.getById(endpoint: '/user', id: id);
  }

  /// Create or sync user profile and resolve role.
  Future<User> createUser(User user) {
    debugPrint("User APi Service, user object: $user");
    final payload = Map<String, dynamic>.from(user.toJson())..remove('id');
    debugPrint("USER Api Service Payload: $payload");
    return _apiService.create(endpoint: '/user', data: payload);
  }

  Future<UserRole?> checkRole() async {
    debugPrint("Sending Check Role API");
    return _apiService.get(
      endpoint: '/users/me',
      parser: (json) => UserRole.values.byName(json['role']),
    );
  }

  Future<bool> verifyAdmin(String password) async {
    return _apiService.post(
      endpoint: '/admin/verification',
      data: {'password': password},
      parser: (json) => json as bool,
    );
  }
}

final usersApiServiceProvider = Provider<UsersApiService>((ref) {
  final apiService = ref.watch(userApiServiceProvider);
  return UsersApiService(apiService);
});
