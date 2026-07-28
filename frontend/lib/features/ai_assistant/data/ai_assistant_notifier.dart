import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_api_service.dart';

/// Notifier for managing AI assistant conversations via real API.
class AiAssistantNotifier extends AsyncNotifier<List<Map<String, String>>> {
  @override
  Future<List<Map<String, String>>> build() async => [];
  bool isStreaming = false;

  Future<void> askAssistant(String query) async {
    debugPrint("Chat Assistant called...");
    final current = state.valueOrNull ?? [];

    // Add user message immediately
    final withUser = [
      ...current,
      {'role': 'user', 'content': query},
      {'role': 'assistant', 'content': ''}, // empty — will be filled by stream
    ];
    state = AsyncValue.data(withUser);

    try {
      final assistanceQuery = AssistanceQuery(
        query: query,
        conversationHistory: current, // send history WITHOUT the new messages
      );
      isStreaming = true;
      await for (final chunk
          in ref
              .read(aiAssistantApiServiceProvider)
              .askAssistantStream(assistanceQuery)) {
        debugPrint(
          "[${DateTime.now().millisecondsSinceEpoch}] notifier updating with: $chunk",
        );

        final currentList = state.valueOrNull ?? [];
        if (currentList.isEmpty) break;

        // Replace the last assistant message by appending the chunk
        final updated = [
          ...currentList.sublist(0, currentList.length - 1),
          {
            'role': 'assistant',
            'content': (currentList.last['content'] ?? '') + chunk,
          },
        ];
        state = AsyncValue.data(updated);
        //isStreaming = false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearHistory() => state = const AsyncValue.data([]);
}

final aiAssistantProvider =
    AsyncNotifierProvider<AiAssistantNotifier, List<Map<String, String>>>(
      AiAssistantNotifier.new,
    );
