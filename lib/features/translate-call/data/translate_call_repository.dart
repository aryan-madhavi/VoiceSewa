// lib/features/translate_call/data/translate_call_repository.dart
//
// Owns all communication with the backend and Firestore for the call lifecycle:
//
//   REST   — POST /session   (create backend session, get sessionId)
//            DELETE /session/:id (tear down on hang-up)
//
//   Firestore — write / update call docs and history entries
//               stream call doc changes for signalling (accept / decline)
//               stream incoming ringing calls addressed to this user
//
//   WebSocket — connect to wss://backend/ws
//               send raw PCM audio chunks (Uint8List binary frames)
//               receive translated PCM audio + JSON control messages
//               keep-alive ping every 20 s

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants.dart';
import '../domain/call_history_entry.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';

// ── WebSocket events (sealed, exhaustively matched in the controller) ─────────

sealed class WsEvent {}

class WsConnectedEvent extends WsEvent {
  WsConnectedEvent({required this.userIndex, required this.sessionId});
  final int userIndex;
  final String sessionId;
}

class WsCallStartedEvent extends WsEvent {
  WsCallStartedEvent({required this.sessionId});
  final String sessionId;
}

class WsTranscriptEvent extends WsEvent {
  WsTranscriptEvent({
    required this.text,
    required this.isFinal,
    required this.lang,
  });
  final String text;
  final bool isFinal;
  final String lang;
}

class WsAudioEvent extends WsEvent {
  WsAudioEvent(this.pcmBytes);
  final Uint8List pcmBytes;
}

class WsPartnerLeftEvent extends WsEvent {}

class WsErrorEvent extends WsEvent {
  WsErrorEvent({required this.code, required this.message});
  final String code;
  final String message;
}

// ── Repository ────────────────────────────────────────────────────────────────

class TranslateCallRepository {
  TranslateCallRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // WebSocket state
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _pingTimer;

  final _wsEventController = StreamController<WsEvent>.broadcast();

  /// Broadcast stream — the call controller subscribes to this.
  Stream<WsEvent> get wsEvents => _wsEventController.stream;

  // ── Auth helper ───────────────────────────────────────────────────────────

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    // forceRefresh: false — use cached token, Firebase refreshes automatically
    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get ID token');
    return token;
  }

  // ── REST: create backend session ──────────────────────────────────────────

  Future<String> createBackendSession() async {
    final token = await _idToken();
    final response = await http.post(
      Uri.parse('${AppConstants.backendBaseUrl}/session'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Backend session creation failed: '
          '${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['sessionId'] as String;
  }

  // ── REST: end backend session ─────────────────────────────────────────────

  Future<void> endBackendSession(String sessionId) async {
    try {
      final token = await _idToken();
      await http.delete(
        Uri.parse('${AppConstants.backendBaseUrl}/session/$sessionId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Best-effort — session will TTL-expire on the backend anyway
    }
  }

  // ── Firestore: create call doc + history entries ──────────────────────────

  Future<void> createCallDoc(CallSession session) async {
    final batch = _firestore.batch();

    // Main signalling doc — both participants read this for status changes
    final callRef = _firestore
        .collection(AppConstants.callsCollection)
        .doc(session.sessionId);
    batch.set(callRef, session.toFirestore());

    // Denormalised history for each participant
    for (final uid in [session.callerUid, session.receiverUid]) {
      final entry = CallHistoryEntry.fromSession(
        session: session,
        currentUid: uid,
      );
      final histRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.callHistorySubcollection)
          .doc(session.sessionId);
      batch.set(histRef, entry.toFirestore());
    }

    await batch.commit();
  }

  // ── Firestore: update call status ─────────────────────────────────────────

  Future<void> updateCallStatus(
    String sessionId,
    CallStatus status, {
    DateTime? endedAt,
    int? durationSeconds,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (endedAt != null) {
      data['endedAt'] = Timestamp.fromDate(endedAt);
    }
    if (durationSeconds != null) {
      data['durationSeconds'] = durationSeconds;
    }

    final batch = _firestore.batch();

    // Update main call doc
    batch.update(
      _firestore.collection(AppConstants.callsCollection).doc(sessionId),
      data,
    );

    // Update both history entries with the same data
    // (We don't know both uids here, so we rely on the controller to pass
    //  them in via updateHistoryEntry if needed — or just let the Firestore
    //  listener on the call doc propagate the status.)

    await batch.commit();
  }

  /// Update a single user's history entry (e.g. after call ends, to set duration).
  Future<void> updateHistoryEntry(
    String uid,
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.callHistorySubcollection)
        .doc(sessionId)
        .update(data);
  }

  // ── Firestore: stream call doc (for signalling) ───────────────────────────

  /// Emits every time the call doc at calls/{sessionId} changes.
  /// Used by the caller to watch for accept / decline / end.
  Stream<CallSession> watchCallSession(String sessionId) {
    return _firestore
        .collection(AppConstants.callsCollection)
        .doc(sessionId)
        .snapshots()
        .where((snap) => snap.exists)
        .map(CallSession.fromFirestore);
  }

  // ── Firestore: stream incoming ringing calls ──────────────────────────────

  /// Emits the most recent ringing call addressed to [receiverUid].
  /// Emits null when no ringing call exists (call answered, declined, etc.).
  /// Used by the app root to show the incoming call screen.
  Stream<CallSession?> watchIncomingCall(String receiverUid) {
    return _firestore
        .collection(AppConstants.callsCollection)
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : CallSession.fromFirestore(snap.docs.first));
  }

  // ── WebSocket: connect ────────────────────────────────────────────────────

  Future<void> connectWebSocket({
    required String sessionId,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    final token = await _idToken();

    final uri = Uri.parse(AppConstants.backendWsUrl).replace(
      queryParameters: {
        'token':      token,
        'sessionId':  sessionId,
        'sourceLang': myLanguage.sourceLang,
        'targetLang': partnerLanguage.targetLang,
        'voiceLang':  partnerLanguage.voiceLang,
      },
    );

    _channel = WebSocketChannel.connect(uri);

    _wsSub = _channel!.stream.listen(
      _onWsData,
      onError: (err) => _wsEventController.add(
        WsErrorEvent(code: 'WS_ERROR', message: err.toString()),
      ),
      onDone: () => _wsEventController.add(WsPartnerLeftEvent()),
    );

    // Keep-alive ping — prevents Cloud Run from closing the idle connection
    _pingTimer = Timer.periodic(AppConstants.wsPingInterval, (_) {
      _sendJson({'type': 'ping'});
    });
  }

  void _onWsData(dynamic data) {
    if (data is List<int>) {
      // Binary frame = translated PCM audio from backend
      _wsEventController.add(WsAudioEvent(Uint8List.fromList(data)));
    } else if (data is Uint8List) {
      _wsEventController.add(WsAudioEvent(data));
    } else if (data is String) {
      try {
        final msg = jsonDecode(data) as Map<String, dynamic>;
        _onWsJson(msg);
      } catch (_) {}
    }
  }

  void _onWsJson(Map<String, dynamic> msg) {
    switch (msg['type'] as String?) {
      case 'connected':
        _wsEventController.add(WsConnectedEvent(
          userIndex: msg['userIndex'] as int,
          sessionId: msg['sessionId'] as String,
        ));
      case 'call_started':
        _wsEventController.add(WsCallStartedEvent(
          sessionId: msg['sessionId'] as String,
        ));
      case 'transcript':
        _wsEventController.add(WsTranscriptEvent(
          text:    msg['text']    as String,
          isFinal: msg['isFinal'] as bool,
          lang:    msg['lang']    as String? ?? '',
        ));
      case 'partner_left':
        _wsEventController.add(WsPartnerLeftEvent());
      case 'error':
        _wsEventController.add(WsErrorEvent(
          code:    msg['code']    as String? ?? 'UNKNOWN',
          message: msg['message'] as String? ?? 'Unknown error',
        ));
      // 'pong' and unknown types are silently ignored
    }
  }

  // ── WebSocket: send audio ─────────────────────────────────────────────────

  void sendAudio(Uint8List pcmBytes) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(pcmBytes);
    } catch (_) {}
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  // ── WebSocket: disconnect ─────────────────────────────────────────────────

  Future<void> disconnectWebSocket() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    disconnectWebSocket();
    _wsEventController.close();
  }
}