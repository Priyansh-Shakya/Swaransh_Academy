import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/profile/domain/profile.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

final userProfileApiServiceProvider = Provider<ApiService<UserProfile>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<UserProfile>(dio: dio, fromJson: UserProfile.fromJson);
});

final studentProfileApiServiceProvider =
    Provider<ApiService<Student>>((ref) {
      final dio = ref.watch(dioProvider);
      return ApiService<Student>(
        dio: dio,
        fromJson: Student.fromJson,
      );
    });
