// lib/features/translate_call/data/translate_call_repository.dart
//
// All communication with the backend and Firestore:
//   REST      — POST /session, DELETE /session/:id
//   Firestore — CRUD call docs, history entries, FCM token fetch, streams
//   WebSocket — connect, send PCM audio, receive events, keep-alive ping

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants.dart';
import '../domain/call_history_entry.dart';
import '../domain/call_language.dart';
import '../domain/call_session.dart';

// ── WebSocket events ──────────────────────────────────────────────────────────

sealed class WsEvent {}

class WsConnectedEvent extends WsEvent {
  WsConnectedEvent({required this.userIndex, required this.sessionId});
  final int    userIndex;
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
  final bool   isFinal;
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
    required FirebaseAuth      auth,
    required FirebaseFirestore firestore,
  })  : _auth      = auth,
        _firestore = firestore;

  final FirebaseAuth      _auth;
  final FirebaseFirestore _firestore;

  WebSocketChannel?            _channel;
  StreamSubscription<dynamic>? _wsSub;
  Timer?                       _pingTimer;

  final _wsEventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get wsEvents => _wsEventController.stream;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<String> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get ID token');
    return token;
  }

  // ── Firestore: fetch receiver FCM token ───────────────────────────────────
  // Called at call-initiation time so we always use the freshest token.

  Future<String?> fetchReceiverFcmToken(String receiverUid) async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(receiverUid)
        .get();
    if (!snap.exists) return null;
    return (snap.data() as Map<String, dynamic>)['fcmToken'] as String?;
  }

  // ── REST: create backend session ──────────────────────────────────────────

  Future<String> createBackendSession() async {
    final token    = await _idToken();
    final response = await http.post(
      Uri.parse('${AppConstants.backendBaseUrl}/session'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type':  'application/json',
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
      // Best-effort — session TTL-expires on backend regardless
    }
  }

  // ── Firestore: create call doc + history entries ──────────────────────────

  Future<void> createCallDoc(CallSession session) async {
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection(AppConstants.callsCollection).doc(session.sessionId),
      session.toFirestore(),
    );

    for (final uid in [session.callerUid, session.receiverUid]) {
      final entry = CallHistoryEntry.fromSession(
        session:    session,
        currentUid: uid,
      );
      batch.set(
        _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .collection(AppConstants.callHistorySubcollection)
            .doc(session.sessionId),
        entry.toFirestore(),
      );
    }

    await batch.commit();
  }

  // ── Firestore: update call status ─────────────────────────────────────────

  Future<void> updateCallStatus(
    String     sessionId,
    CallStatus status, {
    DateTime?  endedAt,
    int?       durationSeconds,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (endedAt != null)        data['endedAt']         = Timestamp.fromDate(endedAt);
    if (durationSeconds != null) data['durationSeconds'] = durationSeconds;

    await _firestore
        .collection(AppConstants.callsCollection)
        .doc(sessionId)
        .update(data);
  }

  // ── Firestore: update history entry ──────────────────────────────────────

  Future<void> updateHistoryEntry(
    String              uid,
    String              sessionId,
    Map<String, dynamic> data,
  ) async {
    // Convert DateTime values to Timestamps for Firestore
    final fsData = data.map((k, v) =>
        MapEntry(k, v is DateTime ? Timestamp.fromDate(v) : v));

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.callHistorySubcollection)
        .doc(sessionId)
        .update(fsData);
  }

  // ── Firestore: stream call doc ────────────────────────────────────────────

  Stream<CallSession> watchCallSession(String sessionId) {
    return _firestore
        .collection(AppConstants.callsCollection)
        .doc(sessionId)
        .snapshots()
        .where((snap) => snap.exists)
        .map(CallSession.fromFirestore);
  }

  // ── Firestore: stream incoming ringing calls ──────────────────────────────

  Stream<CallSession?> watchIncomingCall(String receiverUid) {
    // FIX: Add a createdAt age filter so stale ringing docs left over from
    // crashed/failed calls are ignored. Any ringing doc older than
    // ringingTimeout cannot be a live call — the caller's miss timer
    // would have fired by then. This prevents the app from auto-routing
    // to the incoming call screen on startup due to leftover Firestore docs.
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(AppConstants.ringingTimeout),
    );

    return _firestore
        .collection(AppConstants.callsCollection)
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status',      isEqualTo: CallStatus.ringing.name)
        .where('createdAt',   isGreaterThan: cutoff)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : CallSession.fromFirestore(snap.docs.first));
  }

  // ── Firestore: clean up stale ringing docs for this user ─────────────────
  // Called from CallController.build() on every app start / hot restart.
  // Marks any ringing doc older than ringingTimeout as missed so they never
  // resurface in watchIncomingCall.

  Future<void> cleanupStaleRingingCalls(String callerUid) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(AppConstants.ringingTimeout),
    );

    // Clean up calls the user initiated (as caller) that never got answered
    final staleOutgoing = await _firestore
        .collection(AppConstants.callsCollection)
        .where('callerUid', isEqualTo: callerUid)
        .where('status',    isEqualTo: CallStatus.ringing.name)
        .where('createdAt', isLessThanOrEqualTo: cutoff)
        .get();

    // Clean up calls targeted at this user (as receiver) that were never answered
    final staleIncoming = await _firestore
        .collection(AppConstants.callsCollection)
        .where('receiverUid', isEqualTo: callerUid)
        .where('status',      isEqualTo: CallStatus.ringing.name)
        .where('createdAt',   isLessThanOrEqualTo: cutoff)
        .get();

    final allStale = {...staleOutgoing.docs, ...staleIncoming.docs};
    if (allStale.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in allStale) {
      batch.update(doc.reference, {'status': CallStatus.missed.name});
    }
    await batch.commit();
    debugPrint('[Repo] cleaned up ${allStale.length} stale ringing doc(s)');
  }

  // ── Firestore: update user language ──────────────────────────────────────

  Future<void> updateUserLanguage(String uid, String sourceLang) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set({'language': sourceLang}, SetOptions(merge: true));
  }

  // ── WebSocket: connect ────────────────────────────────────────────────────
  //
  // Calls await _channel!.ready so that any TLS / auth / routing error
  // surfaces immediately as an exception rather than failing silently on
  // the first send.

  Future<void> connectWebSocket({
    required String       sessionId,
    required CallLanguage myLanguage,
    required CallLanguage partnerLanguage,
  }) async {
    // Tear down any existing connection cleanly first
    await disconnectWebSocket();

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

    // await ready throws if the TCP/TLS handshake or the server's HTTP 101
    // upgrade fails — this surfaces errors before we start the audio pipeline.
    try {
      await _channel!.ready;
    } catch (e) {
      _channel = null;
      throw Exception('WebSocket connection failed: $e');
    }

    _wsSub = _channel!.stream.listen(
      _onWsData,
      onError: (err) => _wsEventController.add(
          WsErrorEvent(code: 'WS_ERROR', message: err.toString())),
      onDone: () => _wsEventController.add(WsPartnerLeftEvent()),
    );

    // Keep-alive ping every 20 s — prevents Cloud Run from closing idle conn
    _pingTimer = Timer.periodic(AppConstants.wsPingInterval, (_) {
      _sendJson({'type': 'ping'});
    });
  }

  // ── WebSocket: receive ────────────────────────────────────────────────────

  void _onWsData(dynamic data) {
    if (data is List<int>) {
      _wsEventController.add(WsAudioEvent(Uint8List.fromList(data)));
    } else if (data is Uint8List) {
      _wsEventController.add(WsAudioEvent(data));
    } else if (data is String) {
      try {
        _onWsJson(jsonDecode(data) as Map<String, dynamic>);
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
      // 'pong' and unknown types silently ignored
    }
  }

  // ── WebSocket: send ───────────────────────────────────────────────────────

  void sendAudio(Uint8List pcmBytes) {
    if (_channel == null) return;
    try { _channel!.sink.add(pcmBytes); } catch (_) {}
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_channel == null) return;
    try { _channel!.sink.add(jsonEncode(payload)); } catch (_) {}
  }

  // ── WebSocket: disconnect ─────────────────────────────────────────────────

  Future<void> disconnectWebSocket() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try { await _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    disconnectWebSocket();
    _wsEventController.close();
  }
}