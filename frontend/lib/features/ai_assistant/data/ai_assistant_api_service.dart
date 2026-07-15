import 'package:dio/dio.dart';
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

  /// Ask the AI assistant (streaming not handled here; returns full response).
  Future<String> askAssistant(AssistanceQuery query) async {
    final response = await _dio.post('/assistance', data: query.toJson());
    return response.data as String;
  }
}

final aiAssistantApiServiceProvider = Provider<AiAssistantApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AiAssistantApiService(dio);
});
