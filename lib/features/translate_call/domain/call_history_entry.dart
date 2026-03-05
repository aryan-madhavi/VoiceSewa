// lib/features/translate_call/domain/call_history_entry.dart
//
// Denormalised call log entry stored at:
//   users/{uid}/call_history/{sessionId}
//
// Each user gets their own perspective on the call (direction, their language,
// the other person's name) so the history screen needs no joins.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'call_session.dart';

part 'call_history_entry.freezed.dart';
part 'call_history_entry.g.dart';

/// Whether this user initiated or received the call.
enum CallDirection { outgoing, incoming }

@freezed
class CallHistoryEntry with _$CallHistoryEntry {
  const factory CallHistoryEntry({
    required String sessionId,

    // ── Other participant ───────────────────────────────────────────────────
    required String otherUid,
    required String otherName,

    // ── Languages from this user's perspective ──────────────────────────────
    /// This user's spoken language — BCP-47 sourceLang e.g. "hi-IN"
    required String myLang,

    /// The other participant's language — BCP-47 sourceLang e.g. "en-IN"
    required String otherLang,

    // ── Call metadata ───────────────────────────────────────────────────────
    required CallDirection direction,
    required CallStatus status,
    required DateTime createdAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) = _CallHistoryEntry;

  factory CallHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$CallHistoryEntryFromJson(json);

  /// Deserialise from a Firestore DocumentSnapshot in the call_history subcollection.
  factory CallHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallHistoryEntry.fromJson({
      ...data,
      'sessionId': doc.id,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'endedAt':   data['endedAt'] != null
                     ? (data['endedAt'] as Timestamp).toDate().toIso8601String()
                     : null,
      'status':    data['status'] as String,
      'direction': data['direction'] as String,
    });
  }

  /// Build a history entry from a resolved CallSession, from the perspective
  /// of [currentUid]. Called by the repository when writing history docs.
  factory CallHistoryEntry.fromSession({
    required CallSession session,
    required String currentUid,
  }) {
    final isCallerMe = session.callerUid == currentUid;
    return CallHistoryEntry(
      sessionId:       session.sessionId,
      otherUid:        isCallerMe ? session.receiverUid  : session.callerUid,
      otherName:       isCallerMe ? session.receiverName : session.callerName,
      myLang:          isCallerMe ? session.callerLang   : session.receiverLang,
      otherLang:       isCallerMe ? session.receiverLang : session.callerLang,
      direction:       isCallerMe ? CallDirection.outgoing : CallDirection.incoming,
      status:          session.status,
      createdAt:       session.createdAt,
      endedAt:         session.endedAt,
      durationSeconds: session.durationSeconds,
    );
  }
}

// ── Firestore serialisation extension ─────────────────────────────────────────

extension CallHistoryEntryFirestore on CallHistoryEntry {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt':   endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'status':    status.name,
      'direction': direction.name,
    };
  }
}