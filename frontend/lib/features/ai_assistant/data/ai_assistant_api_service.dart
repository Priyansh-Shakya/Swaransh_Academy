import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';

class AssistanceQuery {
  const AssistanceQuery({
    this.name,
    required this.query,
    required this.conversationHistory,
  });
  final name;
  final String query;
  final List<Map<String, String>> conversationHistory;

  Map<String, dynamic> toJson() => {
    'name': name,
    'query': query,
    'conversation_history': conversationHistory,
  };
}

//? Status of AI responses
sealed class AssistantStreamEvent {}

class AssistantText extends AssistantStreamEvent {
  final String text;

  AssistantText(this.text);
}

class AssistantStatus extends AssistantStreamEvent {
  final String status;

  AssistantStatus(this.status);
}

class AssistantError extends AssistantStreamEvent {
  final String error;

  AssistantError(this.error);
}

/// Feature-specific API service for AI assistance.
class AiAssistantApiService {
  AiAssistantApiService(this._dio);

  final Dio _dio;

  CancelToken? _cancelToken;

  Stream<AssistantStreamEvent> askAssistantStream(
    AssistanceQuery query,
  ) async* {
    _cancelToken = CancelToken();

    try {
      final response = await _dio.post<ResponseBody>(
        '/assistance',
        data: query.toJson(),
        cancelToken: _cancelToken,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      var buffer = '';

      await for (final bytes in stream) {
        buffer += utf8.decode(bytes, allowMalformed: true);

        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmedLine = line.trim();
          if (!trimmedLine.startsWith('data: ')) continue;

          final raw = trimmedLine.substring(6).trim();

          // Standard completion check
          if (raw == '[DONE]' || raw == '"[DONE]"') return;
          if (raw.isEmpty) continue;

          // Legacy status check
          if (raw.startsWith('[STATUS]')) {
            final status = raw.replaceFirst('[STATUS]', '');
            yield AssistantStatus(status);
            continue;
          }

          try {
            final decoded = jsonDecode(raw);

            if (decoded == '[DONE]') return;

            if (decoded is String) {
              yield AssistantText(decoded);
            } else if (decoded is Map<String, dynamic>) {
              final type = decoded['type'];

              if (type == 'status') {
                final statusMsg =
                    decoded['content'] ?? decoded['message'] ?? '';
                yield AssistantStatus(statusMsg);
              } else if (type == 'content') {
                final delta = decoded['delta'] as String?;
                if (delta != null && delta.isNotEmpty) {
                  yield AssistantText(delta);
                }
              } else if (type == 'error') {
                final errorMsg = decoded['message'] ?? 'An error occurred';
                yield AssistantError(errorMsg);
                return; // End stream on error
              } else if (type == 'done') {
                return; // End stream cleanly
              }
            }
          } catch (e) {
            debugPrint("Error parsing SSE line: $e | Line: $raw");
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  void cancelStream() {
    _cancelToken?.cancel("User stopped generation");
    _cancelToken = null;
  }
}

final aiAssistantApiServiceProvider = Provider<AiAssistantApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AiAssistantApiService(dio);
});
