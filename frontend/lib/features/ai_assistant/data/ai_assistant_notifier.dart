import 'package:dio/dio.dart';
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

    // 1. Add user message + placeholder
    final withUser = [
      ...current,
      {'role': 'user', 'content': query},
      {'role': 'assistant', 'content': ''}, // Placeholder for streaming
    ];
    state = AsyncValue.data(withUser);

    try {
      final assistanceQuery = AssistanceQuery(
        name: name,
        query: query,
        conversationHistory: current,
      );

      ref.read(isStreamingProvider.notifier).state = true;

      await for (final event
          in ref
              .read(aiAssistantApiServiceProvider)
              .askAssistantStream(assistanceQuery)) {
        if (event is AssistantStatus) {
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
      // 2. Check if cancellation caused the exception
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint("Stream cancelled successfully by user.");
        _cleanupCancelledState();
      } else {
        // Only set AsyncError if it was an actual unhandled failure
        debugPrint("Error during streaming: $e");
        state = AsyncValue.error(e, st);
      }
    } finally {
      // 3. Guarantee streaming flags are reset
      ref.read(agentStatusProvider.notifier).state = null;
      ref.read(isStreamingProvider.notifier).state = false;
      debugPrint("Streaming set to FALSE");
    }
  }

  void stopStreaming() {
    debugPrint("... Stopping Streaming of Response ...");
    // Calling cancelStream causes Dio to throw a DioException of type cancel,
    // which unblocks the `await for` loop above and routes execution into `catch`.
    ref.read(aiAssistantApiServiceProvider).cancelStream();
  }

  void _cleanupCancelledState() {
    final currentList = List<Map<String, String>>.from(state.valueOrNull ?? []);
    if (currentList.isNotEmpty && currentList.last['role'] == 'assistant') {
      final lastContent = currentList.last['content'] ?? '';
      if (lastContent.isEmpty) {
        // Remove empty assistant placeholder if cancelled before text arrived
        currentList.removeLast();
      }
    }
    state = AsyncValue.data(currentList);
  }

  void clearHistory() => state = const AsyncValue.data([]);
}

final aiAssistantProvider =
    AsyncNotifierProvider<AiAssistantNotifier, List<Map<String, String>>>(
      AiAssistantNotifier.new,
    );

final agentStatusProvider = StateProvider<String?>((ref) => null);
