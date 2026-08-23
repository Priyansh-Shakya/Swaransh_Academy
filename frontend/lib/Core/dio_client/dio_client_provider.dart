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
        debugPrint('========== DIO REQUEST ==========');
        debugPrint('METHOD: ${options.method}');
        debugPrint('URL: ${options.uri}');
        debugPrint('HEADERS BEFORE: ${options.headers}');

        final supabase = ref.read(supabaseProvider);
        final session = supabase.auth.currentSession;

        debugPrint('SESSION EXISTS: ${session != null}');

        if (session != null) {
          final token = session.accessToken;

          options.headers['Authorization'] = 'Bearer $token';

          debugPrint('AUTH HEADER ATTACHED: YES');
          debugPrint('TOKEN LENGTH: ${token.length}');
        } else {
          debugPrint('AUTH HEADER ATTACHED: NO — NO SESSION');
        }

        debugPrint('HEADERS AFTER: ${options.headers}');
        debugPrint('================================');

        handler.next(options);
      },
    ),
  );

  return dio;
});
