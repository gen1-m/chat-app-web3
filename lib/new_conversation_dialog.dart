import 'package:chat_app_web3/supabase_service.dart';
import 'package:material_ui/material_ui.dart';

class NewConversationDialog extends StatefulWidget {
  final String currentUserId;
  final Future<void> Function(
    String userId,
    String userName,
  ) onUserSelected;

  const NewConversationDialog({
    Key? key,
    required this.currentUserId,
    required this.onUserSelected,
  }) : super(key: key);

  @override
  State<NewConversationDialog> createState() =>
      _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final searchController = TextEditingController();

  List<Map<String, dynamic>> results = [];
  bool searching = false;

  // Prevents an older search request from overwriting newer results.
  int searchRequestId = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> searchUsers() async {
    final query = searchController.text.trim();
    final requestId = ++searchRequestId;

    if (query.isEmpty) {
      setState(() {
        results = [];
        searching = false;
      });
      return;
    }

    setState(() {
      searching = true;
      results = [];
    });

    try {
      final found = await SupabaseService.searchProfiles(
        query,
        widget.currentUserId,
      );

      if (!mounted || requestId != searchRequestId) {
        return;
      }

      setState(() {
        results = found;
        searching = false;
      });
    } catch (e) {
      if (!mounted || requestId != searchRequestId) {
        return;
      }

      debugPrint('Error searching users: $e');

      setState(() {
        results = [];
        searching = false;
      });
    }
  }

  Future<void> selectUser(Map<String, dynamic> profile) async {
    final username = profile['username'] as String?;
    final wallet = profile['wallet_address'] as String;
    final userId = profile['id'] as String;

    Navigator.of(context).pop();

    await widget.onUserSelected(
      userId,
      username ?? wallet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Conversation'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => searchUsers(),
              decoration: InputDecoration(
                hintText: 'Username or wallet address',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: searching ? null : searchUsers,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (searching)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),

            if (!searching && results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Search for a user to start a conversation.',
                  textAlign: TextAlign.center,
                ),
              ),

            if (!searching && results.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final profile = results[index];

                    final username =
                        profile['username'] as String?;

                    final wallet =
                        profile['wallet_address'] as String;

                    final avatarUrl =
                        profile['avatar_url'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        username ?? 'Unknown User',
                      ),
                      subtitle: Text(
                        wallet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => selectUser(profile),
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