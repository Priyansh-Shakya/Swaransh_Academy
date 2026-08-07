import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/ai_assistant/data/ai_assistant_api_service.dart';

final isStreamingProvider = StateProvider<bool>((ref) => false);

/// Notifier for managing AI assistant conversations via real API.
class AiAssistantNotifier extends AsyncNotifier<List<Map<String, String>>> {
  @override
  Future<List<Map<String, String>>> build() async => [];

  Future<void> askAssistant(String query, String? name) async {
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
      debugPrint("Name from ask Assistant notifier : $name");

      final assistanceQuery = AssistanceQuery(
        name: name,
        query: query,
        conversationHistory: current, // send history WITHOUT the new messages
      );
      debugPrint(
        "ASSISTANCE QUERY FROM NOTIFIER:\n${assistanceQuery.toJson()}",
      );
      ref.read(isStreamingProvider.notifier).state = true;
      debugPrint("Streaming set to True");
      await for (final event
          in ref
              .read(aiAssistantApiServiceProvider)
              .askAssistantStream(assistanceQuery)) {
        if (event is AssistantStatus) {
          debugPrint("Agent status (Notifier): ${event.status}");

          //* UPDATE AGENT STATUS
          ref.read(agentStatusProvider.notifier).state = event.status;

          continue;
        }

        if (event is AssistantText) {
          final chunk = event.text;

          final currentList = state.valueOrNull ?? [];
          if (currentList.isEmpty) break;

          final updated = [
            ...currentList.sublist(0, currentList.length - 1),
            {
              'role': 'assistant',
              'content': (currentList.last['content'] ?? '') + chunk,
            },
          ];

          state = AsyncValue.data(updated);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      ref.read(agentStatusProvider.notifier).state = null;
      ref.read(isStreamingProvider.notifier).state = false;

      debugPrint("Streaming set to FALSE");
    }
  }

  void stopStreaming() {
    ref.read(aiAssistantApiServiceProvider).cancelStream();

    ref.read(isStreamingProvider.notifier).state = false;
  }

  void clearHistory() => state = const AsyncValue.data([]);
}

final aiAssistantProvider =
    AsyncNotifierProvider<AiAssistantNotifier, List<Map<String, String>>>(
      AiAssistantNotifier.new,
    );

final agentStatusProvider = StateProvider<String?>((ref) => null);
