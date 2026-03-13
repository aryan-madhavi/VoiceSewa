import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/call_constants.dart';
import '../domain/call_state.dart';

typedef TranscriptCallback = void Function(TranscriptEntry entry);
typedef PhaseCallback = void Function(String type);

class CallRepository {
  CallRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  StreamSubscription? _audioSub;
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        // Don't request audio focus — prevents AUDIOFOCUS_LOSS from stopping
        // the microphone recorder when TTS audio plays back.
        audioFocus: AndroidAudioFocus.none,
        audioMode: AndroidAudioMode.inCommunication,
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.voiceCommunication,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.allowBluetooth,
        },
      ),
    ));
  final AudioRecorder _recorder = AudioRecorder();

  // ── Session creation / signalling ──────────────────────────────────────────

  /// POST /session on the backend and write the signalling doc to Firestore.
  Future<String> createSession(String receiverUid, String myLang) async {
    final idToken = await _auth.currentUser!.getIdToken();
    final response = await http.post(
      Uri.parse('${CallConstants.backendUrl}/session'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiverUid': receiverUid}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.body}');
    }

    final sessionId = (jsonDecode(response.body) as Map)['sessionId'] as String;

    // Write signalling doc so the receiver is notified via Firestore stream.
    await _firestore
        .collection(CallFirestoreCollections.calls)
        .doc(sessionId)
        .set({
      'callerUid': _auth.currentUser!.uid,
      'receiverUid': receiverUid,
      'callerLang': myLang,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return sessionId;
  }

  /// Watch Firestore for incoming calls addressed to [uid].
  Stream<CallSignal?> incomingCallStream(String uid) {
    return _firestore
        .collection(CallFirestoreCollections.calls)
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return CallSignal.fromFirestore(doc.id, doc.data());
    });
  }

  /// Mark the Firestore signalling doc as ended.
  Future<void> updateCallStatus(String sessionId, String status) async {
    await _firestore
        .collection(CallFirestoreCollections.calls)
        .doc(sessionId)
        .update({'status': status});
  }

  // ── WebSocket + audio ──────────────────────────────────────────────────────

  /// Connect to the backend WebSocket and start streaming audio.
  ///
  /// [onTranscript] fires for each transcript/translation event.
  /// [onPhase] fires for control messages ('call_started', 'partner_left', etc.)
  Future<void> connect({
    required String sessionId,
    required String lang,
    required TranscriptCallback onTranscript,
    required PhaseCallback onPhase,
  }) async {
    final idToken = await _auth.currentUser!.getIdToken();
    final uri = Uri.parse(
      '${CallConstants.backendWsUrl}/ws'
      '?token=$idToken'
      '&sessionId=$sessionId'
      '&lang=${Uri.encodeComponent(lang)}',
    );

    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    // Listen to incoming messages
    _wsSub = _channel!.stream.listen(
      (message) {
        if (message is String) {
          _handleJsonMessage(message, onTranscript, onPhase);
        } else if (message is List<int>) {
          _playAudio(Uint8List.fromList(message));
        }
      },
      onDone: () => onPhase('disconnected'),
      onError: (_) => onPhase('error'),
    );

    // Start microphone streaming
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    final audioStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _audioSub = audioStream.listen((chunk) {
      if (_channel != null) {
        _channel!.sink.add(Uint8List.fromList(chunk));
      }
    });
  }

  void _handleJsonMessage(
    String raw,
    TranscriptCallback onTranscript,
    PhaseCallback onPhase,
  ) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final type = data['type'] as String?;

    if (type == 'transcript') {
      onTranscript(TranscriptEntry(
        text: data['text'] as String,
        lang: data['lang'] as String,
        isFinal: data['isFinal'] as bool? ?? false,
        isTranslation: data['isTranslation'] as bool? ?? false,
        timestamp: DateTime.now(),
      ));
    } else if (type != null) {
      onPhase(type);
    }
  }

  Future<void> _playAudio(Uint8List bytes) async {
    await _audioPlayer.play(BytesSource(bytes));
  }

  /// Disconnect WebSocket and stop microphone.
  Future<void> disconnect() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
    await _audioPlayer.stop();
  }

  /// End a session via REST + update Firestore.
  Future<void> endSession(String sessionId) async {
    try {
      final idToken = await _auth.currentUser!.getIdToken();
      await http.delete(
        Uri.parse('${CallConstants.backendUrl}/session/$sessionId'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
    } catch (_) {
      // Best effort — always mark Firestore as ended
    }
    await updateCallStatus(sessionId, 'ended');
    await disconnect();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Fires whenever a ringing call addressed to [uid] appears in Firestore.
final incomingCallProvider = StreamProvider.family<CallSignal?, String>((ref, uid) {
  return ref.watch(callRepositoryProvider).incomingCallStream(uid);
});
