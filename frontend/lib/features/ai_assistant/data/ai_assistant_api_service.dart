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

/// Feature-specific API service for AI assistance.
class AiAssistantApiService {
  AiAssistantApiService(this._dio);

  final Dio _dio;

  CancelToken? _cancelToken;

  Stream<String> askAssistantStream(AssistanceQuery query) async* {
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
        debugPrint(
          "RAW BYTE PACKET ${DateTime.now().millisecondsSinceEpoch} size=${bytes.length}",
        );
        buffer += utf8.decode(bytes, allowMalformed: true);

        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final raw = line.substring(6).trim();

            if (raw == '[DONE]') return;
            if (raw.isEmpty) continue;

            final chunk = jsonDecode(raw) as String;

            debugPrint(
              "[FRONTEND RECEIVE] "
              "${DateTime.now().millisecondsSinceEpoch}ms "
              "chunk=$chunk",
            );

            yield chunk;
            Future.delayed(Duration(milliseconds: 80));
          }
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint("Stream cancelled");
        return;
      }

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
