import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/auth/domain/user.dart';

final userApiServiceProvider = Provider<ApiService<User>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<User>(dio: dio, fromJson: User.fromJson);
});
