import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'conversation_list.dart';

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
  final searchController = TextEditingController();

  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadConversations() async {
    try {
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('wallet_address', widget.walletAddress)
          .single();

      final currentUserId = profile['id'] as String;

      final memberships = await supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', currentUserId);

      final result = <Map<String, dynamic>>[];

      for (final membership in memberships) {
        final conversationId = membership['conversation_id'] as String;

        final members = await supabase
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', conversationId)
            .neq('user_id', currentUserId);

        if (members.isEmpty) continue;

        final otherUserId = members.first['user_id'] as String;

        final otherProfile = await supabase
            .from('profiles')
            .select('id, username, wallet_address, avatar_url')
            .eq('id', otherUserId)
            .single();

        final latestMessages = await supabase
            .from('messages')
            .select('content, created_at')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        final latestMessage =
            latestMessages.isNotEmpty ? latestMessages.first : null;

        result.add({
          'conversation_id': conversationId,
          'current_user_id': currentUserId,
          'name': otherProfile['username'] ?? otherProfile['wallet_address'],
          'image_url': otherProfile['avatar_url'] ??
              'https://randomuser.me/api/portraits/men/5.jpg',
          'message': latestMessage?['content'] ?? 'No messages yet',
          'time': latestMessage == null
              ? ''
              : DateFormat('HH:mm').format(
                  DateTime.parse(
                    latestMessage['created_at'],
                  ).toLocal(),
                ),
        });
      }

      if (!mounted) return;

      setState(() {
        conversations = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading conversations: $e'),
        ),
      );
    }
  }

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
                  GestureDetector(
                    onTap: () {},
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
            ),

            const SizedBox(height: 20),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
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
                            searchController.clear();
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
                          isMessageRead: true,
                          conversationId: conversation['conversation_id'],
                          currentUserId: conversation['current_user_id'],
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
