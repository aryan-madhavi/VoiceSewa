import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:voicesewa_client/features/auth/providers/auth_provider.dart';
import 'package:voicesewa_client/features/quotations/firebase/chat_firebase_service.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Provider for ChatFirebaseService
final chatFirebaseServiceProvider = Provider<ChatFirebaseService>((ref) {
  return ChatFirebaseService();
});

/// Params for identifying a chat (job + quotation)
typedef ChatParams = ({String jobId, String quotationId});

/// Stream messages for a specific quotation chat
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, ChatParams>((ref, params) {
      final service = ref.watch(chatFirebaseServiceProvider);
      return service.watchMessages(params.jobId, params.quotationId);
    });

/// Actions for sending messages
class ChatActions {
  final ChatFirebaseService _service;
  final Ref _ref;

  ChatActions(this._service, this._ref);

  Future<String?> sendMessage({
    required String jobId,
    required String quotationId,
    required String originalMsg,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Get sender name from client profile
    final profileAsync = _ref.read(currentClientProfileProvider);
    final senderName = profileAsync.value?.name ?? 'Client';

    return await _service.sendMessage(
      jobId: jobId,
      quotationId: quotationId,
      senderUid: user.uid,
      senderName: senderName,
      originalMsg: originalMsg,
    );
  }
}

final chatActionsProvider = Provider<ChatActions>((ref) {
  final service = ref.watch(chatFirebaseServiceProvider);
  return ChatActions(service, ref);
});
