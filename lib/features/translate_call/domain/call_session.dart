// lib/features/translate_call/domain/call_session.dart
//
// Primary call document — written to Firestore by the caller,
// read by both participants for signalling (accept / decline / end).
//
// Freezed gives us: immutability, copyWith, equality, toString.
// The toFirestore / fromFirestore helpers handle Timestamp conversion
// so the rest of the app works entirely with Dart DateTime.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_session.freezed.dart';
part 'call_session.g.dart';

// ── Call status state machine ─────────────────────────────────────────────────
//
//  idle ──[caller initiates]──► ringing
//          ringing ──[receiver accepts]──► active ──[either hangs up]──► ended
//          ringing ──[receiver declines]──► declined
//          ringing ──[30s timeout]──► missed

enum CallStatus {
  ringing,   // Caller waiting, receiver being notified
  active,    // Both connected, translation pipeline running
  ended,     // Finished normally
  declined,  // Receiver explicitly declined
  missed,    // No answer within ringingTimeout
}

@freezed
class CallSession with _$CallSession {
  const factory CallSession({
    required String sessionId,

    // ── Participants ────────────────────────────────────────────────────────
    required String callerUid,
    required String receiverUid,
    required String callerName,
    required String receiverName,

    // ── Languages (stored as sourceLang BCP-47 codes) ───────────────────────
    /// Caller's spoken language — e.g. "hi-IN"
    required String callerLang,

    /// Receiver's spoken language — e.g. "en-IN"
    required String receiverLang,

    // ── Status ───────────────────────────────────────────────────────────────
    required CallStatus status,
    required DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,

    // ── FCM ──────────────────────────────────────────────────────────────────
    /// Receiver's FCM token — read by the Cloud Function to send the
    /// incoming call notification. Not displayed in the UI.
    String? receiverFcmToken,
  }) = _CallSession;

  // ── JSON (for Freezed / json_serializable) ────────────────────────────────
  factory CallSession.fromJson(Map<String, dynamic> json) =>
      _$CallSessionFromJson(json);

  // ── Firestore helpers ─────────────────────────────────────────────────────

  /// Deserialise from a Firestore DocumentSnapshot.
  /// Converts Firestore Timestamps → Dart DateTime before handing to fromJson.
  factory CallSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallSession.fromJson({
      ...data,
      'sessionId':  doc.id,
      'createdAt':  (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'endedAt':    data['endedAt'] != null
                      ? (data['endedAt'] as Timestamp).toDate().toIso8601String()
                      : null,
      // status is stored as the enum name string e.g. "ringing"
      'status': data['status'] as String,
    });
  }
}

// ── Firestore serialisation extension ────────────────────────────────────────
// Kept as an extension (not inside the Freezed class) to avoid conflicts
// with the generated code.

extension CallSessionFirestore on CallSession {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      // Overwrite ISO string dates with Firestore Timestamps
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt':   endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      // status as name string — Firestore stores "ringing" not the enum index
      'status': status.name,
    };
  }
}