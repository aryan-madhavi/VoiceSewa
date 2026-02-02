import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/model/message_model.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String receiverName;
  final String receiverId;

  const ChatDetailPage({
    Key? key,
    required this.roomId,
    required this.receiverName,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // TODO: Get this from your User Provider/Settings
    // For now, let's assume the current user wants to see 'en' (English)
    // or 'hi' (Hindi). You can make this dynamic later.
    const String myPreferredLang = 'en';

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          // 1. The Chat History Area
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatProvider.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // Show newest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // This is where the MAGIC happens!
                              // It automatically picks the right language for YOU.
                              isMe ? msg.originalMsg : msg.getLocalizedMessage(myPreferredLang),
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg.translatedLanguages.isEmpty && !isMe
                                  ? "Translating..."
                                  : "",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black54
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. The Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    chatProvider.sendMessage(
                      widget.roomId,
                      _controller.text,
                      widget.receiverId,
                    );
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}