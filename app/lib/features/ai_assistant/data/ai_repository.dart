import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/models/result.dart';
import '../../../core/errors/failures.dart';

class AiConversation {
  final String id;
  final String? title;
  final String? projectId;
  final String? modelId;
  final DateTime createdAt;

  const AiConversation({
    required this.id,
    this.title,
    this.projectId,
    this.modelId,
    required this.createdAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      projectId: json['project_id'] as String?,
      modelId: json['model_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AiMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AiRepository {
  final SupabaseClient _client;

  AiRepository(this._client);

  Future<Result<Map<String, dynamic>>> sendMessage({
    required String message,
    String? conversationId,
    String? projectId,
    String provider = 'claude',
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ai-assistant',
        body: {
          'message': message,
          'conversation_id': conversationId,
          'project_id': projectId,
          'provider': provider,
        },
      );

      if (response.status != 200) {
        return Result.failure(
          ServerFailure(response.data?['error'] ?? 'AI request failed'),
        );
      }

      return Result.success(response.data as Map<String, dynamic>);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<AiConversation>>> getConversations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure(const AuthFailure('Not authenticated'));
      }
      final response = await _client
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(50);
      final conversations = (response as List)
          .map((e) => AiConversation.fromJson(e))
          .toList();
      return Result.success(conversations);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<List<AiMessage>>> getMessages(String conversationId) async {
    try {
      final response = await _client
          .from('ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      final messages = (response as List)
          .map((e) => AiMessage.fromJson(e))
          .toList();
      return Result.success(messages);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> deleteConversation(String id) async {
    try {
      await _client.from('ai_conversations').delete().eq('id', id);
      return Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(supabaseClientProvider));
});
