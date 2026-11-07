enum AiRole { user, assistant, system, tool }

class AiMessage {
  final String id;
  final String conversationId;
  final AiRole role;
  final String content;
  final Map<String, dynamic>? toolCalls;
  final Map<String, dynamic>? toolResults;
  final int? tokensUsed;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolResults,
    this.tokensUsed,
    required this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: AiRole.values.firstWhere((r) => r.name == json['role']),
      content: json['content'] as String,
      toolCalls: json['tool_calls'] as Map<String, dynamic>?,
      toolResults: json['tool_results'] as Map<String, dynamic>?,
      tokensUsed: json['tokens_used'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
