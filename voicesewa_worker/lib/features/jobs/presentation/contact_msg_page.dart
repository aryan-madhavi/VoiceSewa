import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/model/chat_room_model.dart';
import '../providers/chat_provider.dart';
import 'chat_detail_page.dart';

class ContactMsgPage extends StatelessWidget {
  const ContactMsgPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        elevation: 0,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return StreamBuilder<List<ChatRoomModel>>(
            stream: chatProvider.myChatsStream,
            builder: (context, snapshot) {
              // 1. Handling Loading State
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Handling Error State
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // 3. Handling Empty State
              final chatRooms = snapshot.data ?? [];
              if (chatRooms.isEmpty) {
                return const Center(
                  child: Text("No messages yet. Start a job to chat!"),
                );
              }

              // 4. The List of Chats
              return ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final room = chatRooms[index];

                  // Logic to figure out "Who am I talking to?"
                  // The room has 2 IDs. We want the one that is NOT mine.
                  final otherUserId = room.participants.firstWhere(
                        (id) => id != myId,
                    orElse: () => 'Unknown',
                  );

                  final otherUserData = room.participantsData[otherUserId] ?? {};
                  final otherUserName = otherUserData['name'] ?? 'User';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(otherUserName[0].toUpperCase()), // First letter of name
                    ),
                    title: Text(
                      otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDate(room.lastUpdated),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                            roomId: room.roomId,
                            receiverName: otherUserName,
                            receiverId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}