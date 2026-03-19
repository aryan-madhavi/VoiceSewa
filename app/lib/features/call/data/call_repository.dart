import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart'
    show AndroidAudioManager, AVAudioSession, AVAudioSessionPortOverride;
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants.dart';
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

  // ── Audio queue ─────────────────────────────────────────────────────────────
  // Each backend TTS response is a complete MP3 utterance. Playing them
  // sequentially prevents clips from cutting each other off.
  final _audioQueue = <Uint8List>[];
  bool _isPlayingAudio = false;
  StreamSubscription? _audioCompleteSub;

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

  Future<String> createSession(String receiverUid, String myLang) async {
    final idToken = await _auth.currentUser!.getIdToken(true); // force refresh
    final response = await http.post(
      Uri.parse('${AppConstants.backendUrl}/session'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiverUid': receiverUid}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.body}');
    }

    final sessionId =
        (jsonDecode(response.body) as Map)['sessionId'] as String;

    await _firestore.collection(FirestoreCollections.calls).doc(sessionId).set({
      'callerUid': _auth.currentUser!.uid,
      'receiverUid': receiverUid,
      'callerLang': myLang,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return sessionId;
  }

  /// Watch Firestore for incoming calls addressed to [uid].
  ///
  /// Filters only by `receiverUid` (single-field index, auto-created by
  /// Firestore) and checks `status == 'ringing'` in Dart. Using two
  /// equality filters in the query would require a composite index that
  /// callers would have to manually create in the Firebase console.
  Stream<CallSignal?> incomingCallStream(String uid) {
    return _firestore
        .collection(FirestoreCollections.calls)
        .where('receiverUid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final ringing =
          snap.docs.where((doc) => doc.data()['status'] == 'ringing');
      if (ringing.isEmpty) return null;
      final doc = ringing.first;
      return CallSignal.fromFirestore(doc.id, doc.data());
    });
  }

  Future<void> updateCallStatus(String sessionId, String status) async {
    await _firestore
        .collection(FirestoreCollections.calls)
        .doc(sessionId)
        .update({'status': status});
  }

  // ── WebSocket + audio ──────────────────────────────────────────────────────

  Future<void> connect({
    required String sessionId,
    required String lang,
    required TranscriptCallback onTranscript,
    required PhaseCallback onPhase,
  }) async {
    final idToken = await _auth.currentUser!.getIdToken(true); // force refresh
    final uri = Uri.parse(
      '${AppConstants.backendWsUrl}/ws'
      '?token=$idToken'
      '&sessionId=$sessionId'
      '&lang=${Uri.encodeComponent(lang)}',
    );

    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    _wsSub = _channel!.stream.listen(
      (message) {
        if (message is String) {
          _handleJsonMessage(message, onTranscript, onPhase);
        } else if (message is List<int>) {
          _enqueueAudio(Uint8List.fromList(message));
        }
      },
      onDone: () => onPhase('disconnected'),
      onError: (_) => onPhase('error'),
    );

    await _startRecording();
    // Route audio to speaker AFTER the recorder has acquired the audio
    // session — calling setSpeaker before recording starts has no effect
    // because the record package resets AudioManager on startStream().
    await setSpeaker(true);
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

  /// Switch audio output between speaker and earpiece.
  Future<void> setSpeaker(bool on) async {
    if (Platform.isAndroid) {
      await AndroidAudioManager().setSpeakerphoneOn(on);
    } else if (Platform.isIOS) {
      await AVAudioSession().overrideOutputAudioPort(
        on ? AVAudioSessionPortOverride.speaker : AVAudioSessionPortOverride.none,
      );
    }
  }

  // ── Audio queue ─────────────────────────────────────────────────────────────

  void _enqueueAudio(Uint8List bytes) {
    _audioQueue.add(bytes);
    if (!_isPlayingAudio) _drainAudioQueue();
  }

  void _drainAudioQueue() {
    if (_audioQueue.isEmpty || _channel == null) {
      _isPlayingAudio = false;
      return;
    }
    _isPlayingAudio = true;
    final bytes = _audioQueue.removeAt(0);
    _audioPlayer.play(BytesSource(bytes));

    // Subscribe to completion so we can play the next clip in the queue.
    // The subscription is cancelled in disconnect() to avoid a dangling
    // listener after the call ends.
    _audioCompleteSub?.cancel();
    _audioCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      _drainAudioQueue();
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

  Future<void> disconnect() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
    _audioCompleteSub?.cancel();
    _audioCompleteSub = null;
    _audioQueue.clear();
    _isPlayingAudio = false;
    await _audioPlayer.stop();
  }

  Future<void> endSession(String sessionId) async {
    try {
      final idToken = await _auth.currentUser!.getIdToken(true); // force refresh
      await http.delete(
        Uri.parse('${AppConstants.backendUrl}/session/$sessionId'),
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
final incomingCallProvider =
    StreamProvider.family<CallSignal?, String>((ref, uid) {
  return ref.watch(callRepositoryProvider).incomingCallStream(uid);
});
