import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  debugPrint("Dio Base URL: $baseUrl");
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage/provider
        // Create your token provider and then uncomment this code.
        final supabase = ref.read(supabaseProvider);
        final session = supabase.auth.currentSession;
        if (session != null) {
          final token = session.accessToken;
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint("AUTH TOKEN: ${token.substring(0, 5)}");
        }

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
