import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/courses/domain/course.dart';

final courseApiServiceProvider = Provider<ApiService<Course>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<Course>(dio: dio, fromJson: Course.fromJson);
});
