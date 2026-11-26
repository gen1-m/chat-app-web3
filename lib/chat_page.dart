import 'package:chat_app_web3/chat_detail.dart';
import 'package:chat_app_web3/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conversation_list.dart';
import 'new_conversation_dialog.dart';

class ChatPage extends StatefulWidget {
  final String walletAddress;

  const ChatPage({
    Key? key,
    required this.walletAddress,
  }) : super(key: key);

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;
  final conversationSearchController = TextEditingController();

  RealtimeChannel? conversationsChannel;

  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = '';
  String? currentUserId;

// initState
  @override
  void initState() {
    super.initState();

    loadConversations();
    subscribeToConversations();
  }

// ----------------------- subscribeToConversations --------------------------
  void subscribeToConversations() {
    conversationsChannel = supabase
        .channel('conversation-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            final newMessage = payload.newRecord;
            final conversationId = newMessage['conversation_id'];

            final index = conversations.indexWhere(
              (conversation) =>
                  conversation['conversation_id'] == conversationId,
            );

            if (index == -1) {
              await loadConversations(refresh: true);
              return;
            }

            await loadConversations(refresh: true);
          },
        )
        .subscribe();
  }

// ----------------------- loadConversations --------------------------
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isRefreshing = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('wallet_address', widget.walletAddress)
          .single();

      currentUserId = profile['id'] as String;

      final rows = await supabase.rpc(
        'get_user_conversations',
      );

      final result = List<Map<String, dynamic>>.from(rows).map((row) {
        final createdAt = row['created_at'];
        final lastReadAt = row['last_read_at'];
        final senderId = row['sender_id'];

        return {
          'conversation_id': row['conversation_id'],
          'current_user_id': row['current_user_id'],
          'name': row['name'],
          'image_url': row['image_url'] ??
              'https://randomuser.me/api/portraits/men/5.jpg',
          'message': row['message'] ?? 'No messages yet',
          'time': createdAt == null
              ? ''
              : DateFormat('HH:mm').format(
                  DateTime.parse(createdAt).toLocal(),
                ),
          'isUnread': senderId != currentUserId &&
              lastReadAt != null &&
              createdAt != null &&
              DateTime.parse(createdAt).isAfter(
                DateTime.parse(lastReadAt),
              ),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        conversations = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

// ----------------------- startConversation --------------------------
  Future<void> startConversation(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      final conversationId = await SupabaseService.getOrCreateConversation(
        currentUserId!,
        otherUserId,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            user: otherUserName,
            conversationId: conversationId,
            currentUserId: currentUserId!,
          ),
        ),
      );

      await loadConversations(refresh: true);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
    }
  }

// ----------------------- openNewConversationDialog --------------------------
  Future<void> openNewConversationDialog() async {
    if (currentUserId == null) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return NewConversationDialog(
          currentUserId: currentUserId!,
          onUserSelected: startConversation,
        );
      },
    );
  }

// ----------------------- filteredConversations --------------------------
  List<Map<String, dynamic>> get filteredConversations {
    if (searchQuery.isEmpty) {
      return conversations;
    }

    return conversations.where((conversation) {
      final name = conversation['name'].toString().toLowerCase();
      final message = conversation['message'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query) || message.contains(query);
    }).toList();
  }

// dispose
  @override
  void dispose() {
    conversationSearchController.dispose();
    conversationsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filtered = filteredConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Conversations',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: isRefreshing
                              ? null
                              : () => loadConversations(refresh: true),
                          icon: isRefreshing
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: openNewConversationDialog,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.pink,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),

            const SizedBox(height: 20),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: conversationSearchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 21,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          onPressed: () {
                            conversationSearchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Conversations
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              searchQuery.isEmpty
                                  ? Icons.chat_bubble_outline
                                  : Icons.search_off,
                              size: 52,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No conversations yet'
                                  : 'No conversations found',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              searchQuery.isEmpty
                                  ? 'Start a conversation to see it here.'
                                  : 'Try searching for another name or message.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 20,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conversation = filtered[index];

                        return ConversationList(
                          name: conversation['name'],
                          messageText: conversation['message'],
                          imageUrl: conversation['image_url'],
                          time: conversation['time'],
                          isMessageRead: !conversation['isUnread'],
                          conversationId: conversation['conversation_id'],
                          currentUserId: conversation['current_user_id'],
                          onConversationOpened: () =>
                              loadConversations(refresh: true),
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
