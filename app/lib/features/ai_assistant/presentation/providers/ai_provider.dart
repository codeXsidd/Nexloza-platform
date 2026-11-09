import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai_repository.dart';

enum AiProvider { claude, grok }

extension AiProviderX on AiProvider {
  String get displayName => switch (this) {
    AiProvider.claude => 'Claude (Bedrock)',
    AiProvider.grok => 'Grok (xAI)',
  };

  String get key => switch (this) {
    AiProvider.claude => 'claude',
    AiProvider.grok => 'grok',
  };
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AiChatState {
  final List<ChatMessage> messages;
  final String? conversationId;
  final String? projectId;
  final AiProvider provider;
  final bool isSending;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.conversationId,
    this.projectId,
    this.provider = AiProvider.claude,
    this.isSending = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    String? conversationId,
    String? projectId,
    AiProvider? provider,
    bool? isSending,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      projectId: projectId ?? this.projectId,
      provider: provider ?? this.provider,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiRepository _repo;

  AiChatNotifier(this._repo) : super(const AiChatState());

  void setProvider(AiProvider provider) {
    state = state.copyWith(provider: provider);
  }

  void setProjectId(String? projectId) {
    state = state.copyWith(projectId: projectId);
  }

  void clearChat() {
    state = const AiChatState();
  }

  Future<void> loadConversation(String conversationId) async {
    final result = await _repo.getMessages(conversationId);
    result.when(
      success: (messages) {
        final chatMessages = messages
            .map(
              (m) => ChatMessage(
                text: m.content,
                isUser: m.role == 'user',
                timestamp: m.createdAt,
              ),
            )
            .toList();
        state = state.copyWith(
          messages: chatMessages,
          conversationId: conversationId,
        );
      },
      failure: (_) {},
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      error: null,
    );

    final result = await _repo.sendMessage(
      message: text,
      conversationId: state.conversationId,
      projectId: state.projectId,
      provider: state.provider.key,
    );

    result.when(
      success: (data) {
        final content = data['content'] as String? ?? 'No response';
        final convId = data['conversation_id'] as String?;
        final assistantMsg = ChatMessage(text: content, isUser: false);
        state = state.copyWith(
          messages: [...state.messages, assistantMsg],
          conversationId: convId ?? state.conversationId,
          isSending: false,
        );
      },
      failure: (f) {
        final errorMsg = ChatMessage(
          text: 'Error: ${f.message}',
          isUser: false,
        );
        state = state.copyWith(
          messages: [...state.messages, errorMsg],
          isSending: false,
          error: f.message,
        );
      },
    );
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((
  ref,
) {
  return AiChatNotifier(ref.watch(aiRepositoryProvider));
});

final aiConversationsProvider = FutureProvider<List<AiConversation>>((
  ref,
) async {
  final repo = ref.watch(aiRepositoryProvider);
  final result = await repo.getConversations();
  return result.when(
    success: (data) => data,
    failure: (f) => throw Exception(f.message),
  );
});
