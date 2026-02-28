import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/features/jobs/presentation/voice_call_page.dart';
import 'package:voicesewa_worker/features/jobs/providers/job_provider.dart';
import 'package:voicesewa_worker/features/profile/providers/worker_profile_provider.dart';
import 'package:voicesewa_worker/shared/models/job_model.dart';
import '../../../core/providers/language_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final JobModel job;
  final String quotationId;

  const ChatPage({super.key, required this.job, required this.quotationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final originalMsg = _msgCtrl.text.trim();
    if (originalMsg.isEmpty || _sending) return;

    _msgCtrl.clear();
    setState(() => _sending = true);

    try {
      final uid = ref.read(currentWorkerUidProvider);
      final profile = ref.read(workerProfileStreamProvider(uid)).value;

      final String? newMessageId = await ref.read(sendMessageProvider)(
        jobId: widget.job.jobId,
        quotationId: widget.quotationId,
        originalMsg: originalMsg,
        senderName: profile?.name ?? 'Worker',
      );

      if (newMessageId != null) {
        await _chatTranslationN8NWebhook(
          jobId: widget.job.jobId,
          quotationId: widget.quotationId,
          messageId: newMessageId,
        );
      }
    } catch (e) {
      debugPrint("Failed to send: $e");
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _chatTranslationN8NWebhook({
   required String jobId,
   required String quotationId,
   required String messageId,
  })async{
      final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/translate");

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type" : "application/json"},
          body: jsonEncode({
            "jobId": jobId,
            "quotationId": quotationId,
            "messageId": messageId,
          }),
        );
        if (response.statusCode != 200){
          debugPrint("Chat Translation N8N Webhook Error: ${response.statusCode}");
        }
      }
      catch(e){
        debugPrint("Failed to reach N8N: $e");
      }
    }

  Future<void> _callClient(String clientName) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceCallPage(
          // channelId: widget.job.jobId,
          clientName: clientName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProfileProvider(widget.job.clientUid));
    final clientName = clientAsync.value?['name'] ?? 'Client';
    final messages = ref.watch(
      chatMessagesProvider((widget.job.jobId, widget.quotationId)),
    );

    return Scaffold(
      backgroundColor: ColorConstants.chatBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Chat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.job.serviceName,
              style: const TextStyle(
                fontSize: 11,
                color: ColorConstants.textGrey,
              ),
            ),
          ],
        ),
        backgroundColor: ColorConstants.pureWhite,
        foregroundColor: ColorConstants.textDark,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _callClient(clientName),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call,
                  color: ColorConstants.successGreen,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 52,
                          color: ColorConstants.dividerGrey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            color: ColorConstants.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Start the conversation below',
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorConstants.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConstants.pureWhite,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.shadowBlack.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: ColorConstants.chatBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _sending
                      ? ColorConstants.sendingGrey
                      : ColorConstants.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorConstants.pureWhite,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: ColorConstants.pureWhite,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Bubble ────────────────────────────────────────────────────────────

class _Bubble extends ConsumerWidget { // Change to ConsumerWidget
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    final isMe = msg.isWorker;
    final time = msg.sentAt != null ? _fmt(msg.sentAt!) : '';

    final currentLocale = ref.watch(localeProvider);
    final String langCode = currentLocale.languageCode;

    final String displayMsg = msg.translated[langCode] ?? msg.originalMsg;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: ColorConstants.dividerGrey,
              child: Icon(Icons.person_outline, size: 16, color: ColorConstants.textGrey),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      msg.senderName,
                      style: const TextStyle(fontSize: 11, color: ColorConstants.textGrey, fontWeight: FontWeight.w500),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? ColorConstants.primaryBlue : ColorConstants.pureWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    displayMsg, // <--- Use the displayMsg variable here
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? ColorConstants.pureWhite : ColorConstants.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: const TextStyle(fontSize: 10, color: ColorConstants.textGrey)),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }


  String _fmt(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }
}
