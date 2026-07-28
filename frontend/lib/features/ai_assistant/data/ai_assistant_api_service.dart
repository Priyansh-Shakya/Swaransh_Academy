import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';

class AssistanceQuery {
  const AssistanceQuery({
    required this.query,
    required this.conversationHistory,
  });

  final String query;
  final List<Map<String, String>> conversationHistory;

  Map<String, dynamic> toJson() => {
    'query': query,
    'conversation_history': conversationHistory,
  };
}

/// Feature-specific API service for AI assistance.
class AiAssistantApiService {
  AiAssistantApiService(this._dio);

  final Dio _dio;

  // /// Ask the AI assistant (streaming not handled here; returns full response).
  // Future<String> askAssistant(AssistanceQuery query) async {
  //   final response = await _dio.post('/assistance', data: query.toJson());
  //   return response.data as String;
  // }
  /// Returns a stream of text chunks as they arrive from the server.
  Stream<String> askAssistantStream(AssistanceQuery query) async* {
    debugPrint("Chat Stream API Called: ${query.query}");
    final response = await _dio.post<ResponseBody>(
      '/assistance',
      data: query.toJson(),
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream;
    var buffer = '';

    await for (final bytes in stream) {
      buffer += utf8.decode(bytes, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // keep incomplete tail for next read

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final raw = line.substring(6).trim();
          if (raw == '[DONE]') return;
          if (raw.isEmpty) continue;

          final chunk = jsonDecode(raw) as String;
          yield chunk;

          // Add micro-delay so ultra-fast streams still look like typing
          await Future.delayed(const Duration(milliseconds: 25));
        }
      }
    }
  }
}

final aiAssistantApiServiceProvider = Provider<AiAssistantApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AiAssistantApiService(dio);
});
