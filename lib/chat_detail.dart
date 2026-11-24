import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'supabase_service.dart';

// ----------------------- Declarations --------------------------
class ChatDetailPage extends StatefulWidget {
  final String user;
  final String conversationId;
  final String currentUserId;

  const ChatDetailPage({
    Key? key,
    required this.user,
    required this.conversationId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  ChatDetailPageState createState() => ChatDetailPageState();
}

// ----------------------- The state --------------------------
class ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController messageController = TextEditingController();
  final supabase = Supabase.instance.client;

  RealtimeChannel? messagesChannel;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;

  // init state
  @override
  void initState() {
    super.initState();

    loadMessages();
    subscribeToMessages();
  }

  // ----------------------- subscribeToMessages --------------------------
  void subscribeToMessages() {
    messagesChannel = supabase
        .channel('messages:${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;

            if (!mounted) return;

            setState(() {
              if (!messages
                  .any((message) => message['id'] == newMessage['id'])) {
                messages.add(newMessage);
              }
            });
          },
        )
        .subscribe();
  }

  // ----------------------- loadMessages --------------------------
  Future<void> loadMessages() async {
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load messages: $e'),
        ),
      );
    }
  }

  // ----------------------- sendMessage --------------------------
  Future<void> sendMessage() async {
    final content = messageController.text.trim();

    if (content.isEmpty || isSending) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await SupabaseService.sendMessage(
        widget.conversationId,
        widget.currentUserId,
        content,
      );

      messageController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // dispose
  @override
  void dispose() {
    messagesChannel?.unsubscribe();
    messageController.dispose();
    super.dispose();
  }

  // ----------------------- Main Component --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
            ),
            const CircleAvatar(
              radius: 21,
              backgroundImage: NetworkImage(
                'https://randomuser.me/api/portraits/men/5.jpg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_vert,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Messages
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (messages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Send a message to start the conversation.',
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
          else
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                90,
              ),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSender = message['sender_id'] == widget.currentUserId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment:
                        isSender ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isSender
                            ? Colors.blue.shade500
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                            isSender ? 18 : 4,
                          ),
                          bottomRight: Radius.circular(
                            isSender ? 4 : 18,
                          ),
                        ),
                      ),
                      child: Text(
                        message['content'] ?? '',
                        style: TextStyle(
                          color: isSender ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Message composer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.grey.shade700,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 42,
                          maxHeight: 110,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter) {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                return KeyEventResult.ignored;
                              }

                              sendMessage();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: messageController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Write a message...',
                              hintStyle: TextStyle(
                                color: Colors.black45,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isSending ? null : sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSending
                              ? Colors.blue.shade200
                              : Colors.blue.shade500,
                          shape: BoxShape.circle,
                        ),
                        child: isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
