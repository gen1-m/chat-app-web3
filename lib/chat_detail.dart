import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

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

class ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController messageController = TextEditingController();

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);

    setState(() {
      messages = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> sendMessage() async {
    final content = messageController.text.trim();

    if (content.isEmpty) {
      return;
    }

    try {
      await SupabaseService.sendMessage(
        widget.conversationId,
        widget.currentUserId,
        content,
      );

      messageController.clear();

      await loadMessages();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 2),
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/men/5.jpg",
                  ),
                  maxRadius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        widget.user,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Online",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.settings,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            // reverse: true,
            itemCount: messages.length,
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 70,
            ),
            itemBuilder: (context, index) {
              final message = messages[index];
              
              final isSender = message['sender_id'] == widget.currentUserId;

              return Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: 10,
                ),
                child: Align(
                  alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSender ? Colors.blue[200] : Colors.grey.shade200,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      message['content'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.only(
                left: 10,
                bottom: 10,
                top: 10,
              ),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Write message...",
                        hintStyle: TextStyle(
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: sendMessage,
                    backgroundColor: Colors.blue,
                    elevation: 0,
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
