import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_state.freezed.dart';

/// The phase the call feature is currently in.
@freezed
class CallPhase with _$CallPhase {
  const factory CallPhase.idle() = IdlePhase;

  /// We placed a call and are waiting for the other party.
  const factory CallPhase.outgoing({
    required String sessionId,
    required String receiverUid,
  }) = OutgoingPhase;

  /// Incoming call detected via Firestore.
  const factory CallPhase.incoming({
    required String sessionId,
    required String callerUid,
    required String callerLang,
  }) = IncomingPhase;

  /// WebSocket connecting / both parties joining.
  const factory CallPhase.connecting({
    required String sessionId,
  }) = ConnectingPhase;

  /// Both parties connected, audio flowing.
  const factory CallPhase.active({
    required String sessionId,
  }) = ActivePhase;

  const factory CallPhase.ended({String? reason}) = EndedPhase;
}

/// A single line in the transcript shown during an active call.
class TranscriptEntry {
  const TranscriptEntry({
    required this.text,
    required this.lang,
    required this.isFinal,
    required this.isTranslation,
    required this.timestamp,
  });

  final String text;
  final String lang;
  final bool isFinal;
  final bool isTranslation;
  final DateTime timestamp;
}

/// Firestore signalling document under calls/{sessionId}.
class CallSignal {
  const CallSignal({
    required this.sessionId,
    required this.callerUid,
    required this.receiverUid,
    required this.callerLang,
    required this.status,
  });

  final String sessionId;
  final String callerUid;
  final String receiverUid;
  final String callerLang;
  final String status; // 'ringing' | 'active' | 'ended'

  factory CallSignal.fromFirestore(String id, Map<String, dynamic> data) {
    return CallSignal(
      sessionId: id,
      callerUid: data['callerUid'] as String,
      receiverUid: data['receiverUid'] as String,
      callerLang: data['callerLang'] as String? ?? 'en-IN',
      status: data['status'] as String? ?? 'ringing',
    );
  }

  Map<String, dynamic> toMap() => {
        'callerUid': callerUid,
        'receiverUid': receiverUid,
        'callerLang': callerLang,
        'status': status,
        'createdAt': DateTime.now().toIso8601String(),
      };
}
