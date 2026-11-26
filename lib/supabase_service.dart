import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<Map<String, dynamic>> getOrCreateProfile(
    String walletAddress,
  ) async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated Supabase user');
    }

    final existing =
        await client.from('profiles').select().eq('id', user.id).maybeSingle();

    if (existing != null) {
      return existing;
    }

    final created = await client
        .from('profiles')
        .insert({
          'id': user.id,
          'wallet_address': walletAddress,
        })
        .select()
        .single();

    return created;
  }

  static Future<String> createConversation(
    String otherUserId,
  ) async {
    final conversationId = await client.rpc(
      'create_conversation',
      params: {
        'p_other_user_id': otherUserId,
      },
    );

    return conversationId as String;
  }

  static Future<String> getOrCreateConversation(
    String userId,
    String otherUserId,
  ) async {
    final existing = await client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId);

    for (final row in existing) {
      final conversationId = row['conversation_id'];

      final otherMember = await client
          .from('conversation_members')
          .select()
          .eq('conversation_id', conversationId)
          .eq('user_id', otherUserId)
          .maybeSingle();

      if (otherMember != null) {
        return conversationId as String;
      }
    }

    return createConversation(otherUserId);
  }

  static Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String senderId,
    String content,
  ) async {
    final message = await client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();

    return message;
  }

  static Future<List<Map<String, dynamic>>> searchProfiles(
    String query,
    String currentUserId,
  ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = await client
        .from('profiles')
        .select()
        .neq('id', currentUserId)
        .or(
          'username.ilike.%${query.trim()}%,'
          'wallet_address.ilike.%${query.trim()}%',
        )
        .limit(10);

    return List<Map<String, dynamic>>.from(results);
  }

  static Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    await client
        .from('conversation_members')
        .update({
          'last_read_at':
              DateTime.now().toUtc().toIso8601String(), // formatting the date
        })
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }
}
