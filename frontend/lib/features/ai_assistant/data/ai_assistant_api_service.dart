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
          if (!line.startsWith('data: ')) continue;

          final raw = line.substring(6).trim();

          if (raw == '[DONE]') return;
          if (raw.isEmpty) continue;

          if (raw.startsWith('[STATUS]')) {
            final status = raw.replaceFirst('[STATUS]', '');
            debugPrint("Setting Agent Status API:$status");
            yield AssistantStatus(status);
            continue;
          }

          final chunk = jsonDecode(raw) as String;

          yield AssistantText(chunk);
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
