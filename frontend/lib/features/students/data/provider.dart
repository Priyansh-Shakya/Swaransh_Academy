import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

final studentApiServiceProvider = Provider<ApiService<Student>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<Student>(dio: dio, fromJson: Student.fromJson);
});
