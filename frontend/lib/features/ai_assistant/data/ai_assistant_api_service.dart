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

          var raw = trimmedLine.substring(6).trim();

          // Standard completion check
          if (raw == '[DONE]' || raw == '"[DONE]"') return;
          if (raw.isEmpty) continue;

          // 1. Handle [STATUS]: or [STATUS] (with or without colon/spaces)
          if (raw.startsWith('[STATUS]')) {
            var statusContent = raw.replaceFirst(
              RegExp(r'^\[STATUS\]:?\s*'),
              '',
            );

            // Format if it's a ToolCall string
            if (statusContent.contains('ToolCall(')) {
              statusContent = formatToolStatus(statusContent);
            }

            yield AssistantStatus(statusContent);
            continue;
          }

          // 2. Catch tool calls emitted without [STATUS] prefix
          if (raw.startsWith('ToolCall(') || raw.startsWith('[ToolCall(')) {
            yield AssistantStatus(formatToolStatus(raw));
            continue;
          }

          try {
            final decoded = jsonDecode(raw);

            if (decoded == '[DONE]') return;

            if (decoded is String) {
              // Extra safety check in case decoded JSON is a [STATUS] string
              // Handle legacy or plain string status checks with or without colon
              if (raw.startsWith('[STATUS]')) {
                final status = raw.replaceFirst(
                  RegExp(r'^\[STATUS\]:?\s*'),
                  '',
                );
                yield AssistantStatus(status);
                continue;
              } else {
                yield AssistantText(decoded);
              }
            } else if (decoded is Map<String, dynamic>) {
              final type = decoded['type'];

              if (type == 'status') {
                final statusMsg =
                    decoded['content'] ?? decoded['message'] ?? '';
                yield AssistantStatus(formatToolStatus(statusMsg.toString()));
              } else if (type == 'content') {
                final delta = decoded['delta'] as String?;
                if (delta != null && delta.isNotEmpty) {
                  yield AssistantText(delta);
                }
              } else if (type == 'error') {
                final errorMsg = decoded['message'] ?? 'An error occurred';
                yield AssistantError(errorMsg);
                return;
              } else if (type == 'done') {
                return;
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

//* Tool Call Fornmatore for HOOD
String formatToolStatus(String raw) {
  final nameMatch = RegExp(r'''name=['"]([^'"]+)''').firstMatch(raw);
  final toolName = nameMatch?.group(1);

  if (toolName == 'get_tables_schema') {
    final tableMatch = RegExp(
      r'''tables['"]?:\s*\[?['"]([^'"\]]+)''',
    ).firstMatch(raw);

    final table = tableMatch?.group(1) ?? 'database';
    return "Checking $table schema...";
  }

  if (toolName == 'sql_execute') {
    return "Querying database...";
  }

  if (toolName != null) {
    final clean = toolName.replaceAll('_', ' ');
    return "Executing $clean...";
  }

  return raw.trim();
}
