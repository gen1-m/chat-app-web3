import 'package:material_ui/material_ui.dart';
import 'package:chat_app_web3/chat_detail.dart';

class ConversationList extends StatelessWidget {
  final String name;
  final String messageText;
  final String imageUrl;
  final String time;
  final bool isMessageRead;
  final String conversationId;
  final String currentUserId;

  const ConversationList({
    super.key,
    required this.name,
    required this.messageText,
    required this.imageUrl,
    required this.time,
    required this.isMessageRead,
    required this.conversationId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailPage(
              user: name,
              conversationId: conversationId,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    messageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: isMessageRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: isMessageRead
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}