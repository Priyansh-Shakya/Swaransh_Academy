import "package:dio/dio.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage/provider
        //! Create your token provider and then uncomment this code.
        // final token = ref.read(authTokenProvider);

        // if (token != null && token.isNotEmpty) {
        //   options.headers['Authorization'] = 'Bearer $token';
        // }

        handler.next(options);
      },

      onError: (error, handler) async {
        // Handle 401 refresh/logout/etc
        handler.next(error);
      },

      onResponse: (response, handler) {
        handler.next(response);
      },
    ),
  );

  return dio;
});
