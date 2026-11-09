import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../theme/app_spacing.dart';
import '../providers/ai_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/ai_suggestion_card.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(aiChatProvider);

    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.aiAssistant),
        actions: [
          PopupMenuButton<AiProvider>(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'AI Provider',
            onSelected: (provider) {
              ref.read(aiChatProvider.notifier).setProvider(provider);
            },
            itemBuilder: (_) => AiProvider.values
                .map(
                  (p) => PopupMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        if (p == chatState.provider)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          )
                        else
                          const SizedBox(width: 18),
                        AppSpacing.horizontalSm,
                        Text(p.displayName),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Conversations',
            onPressed: () => _showConversationHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: () => ref.read(aiChatProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.provider != AiProvider.claude)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.colorScheme.tertiaryContainer,
              child: Text(
                'Using ${chatState.provider.displayName}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcome(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.screenPadding,
                    itemCount:
                        chatState.messages.length +
                        (chatState.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length &&
                          chatState.isSending) {
                        return _buildTypingIndicator(theme);
                      }
                      final msg = chatState.messages[index];
                      return ChatBubble(text: msg.text, isUser: msg.isUser);
                    },
                  ),
          ),
          _buildInputBar(theme, chatState.isSending),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isSending) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !isSending,
                decoration: InputDecoration(
                  hintText: isSending ? 'Thinking...' : AppStrings.askAi,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : _sendMessage,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Text('Thinking...', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 80, color: theme.colorScheme.primary),
            AppSpacing.verticalMd,
            Text(
              AppStrings.aiWelcome,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            AiSuggestionCard(
              suggestions: const [
                'Why is my ESP32 offline?',
                'Create an automation for soil moisture',
                'Generate ESP32 code for DHT22',
                'Explain today\'s temperature readings',
              ],
              onSuggestionTap: (suggestion) {
                _messageController.text = suggestion;
                _sendMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConversationHistory(BuildContext context) {
    final theme = Theme.of(context);
    final conversations = ref.read(aiConversationsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Conversations', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: conversations.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (convos) {
                  if (convos.isEmpty) {
                    return const Center(
                      child: Text('No previous conversations'),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: convos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final c = convos[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_outlined),
                        title: Text(c.title ?? 'Untitled'),
                        subtitle: Text(
                          c.modelId ?? 'claude',
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {
                          ref
                              .read(aiChatProvider.notifier)
                              .loadConversation(c.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
