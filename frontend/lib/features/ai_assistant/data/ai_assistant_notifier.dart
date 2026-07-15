import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_api_service.dart';

/// Notifier for managing AI assistant conversations via real API.
class AiAssistantNotifier extends AsyncNotifier<List<Map<String, String>>> {
  @override
  Future<List<Map<String, String>>> build() async {
    // Start with an empty conversation history
    return [];
  }

  /// Send a query to the AI assistant and update conversation history.
  Future<void> askAssistant(String query) async {
    final current = state.valueOrNull ?? [];
    state = const AsyncValue.loading();

    try {
      final assistanceQuery = AssistanceQuery(
        query: query,
        conversationHistory: current,
      );

      final response = await ref
          .read(aiAssistantApiServiceProvider)
          .askAssistant(assistanceQuery);

      // Update conversation history with user query and assistant response
      final updatedHistory = [
        ...current,
        {'role': 'user', 'content': query},
        {'role': 'assistant', 'content': response},
      ];

      state = AsyncValue.data(updatedHistory);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clear conversation history.
  void clearHistory() {
    state = const AsyncValue.data([]);
  }
}

final aiAssistantProvider =
    AsyncNotifierProvider<AiAssistantNotifier, List<Map<String, String>>>(
      AiAssistantNotifier.new,
    );
