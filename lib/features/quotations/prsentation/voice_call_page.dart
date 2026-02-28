import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

// --- SHARED TEST CONFIG (Must match exactly on both apps) ---
const String tempAppId = "e7f6e9aeecf14b2ba10e3f40be9f56e7";
const String tempToken = "007eJxTYND87Zb0c+N/vResb0pl/mUKGMyXnSHqumXqVvmMBQd/9E1WYEhONEg2STUxNU9ONjexTE5LSkkyMjE0SzIwMUgzM0010124KLMhkJFh1+Z+FkYGCATxORlKUotL4pMTc3IYGABY+iMB";
const String staticChannelName = "test_call";
// ---------------------------------------------------------

class VoiceCallPage extends StatefulWidget {
  final String workerName;
  final String workerId;
  final String jobId;

  const VoiceCallPage({
    super.key,
    required this.workerName,
    required this.jobId,
    required this.workerId,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  late RtcEngine _engine;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _joined = false;
  bool _muted = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _startCallSequence();
  }

  // Future<void> _sendCallNotification() async {
  //   final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/call-notification");
  //   try {
  //     await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({
  //         "receiverId": widget.workerId,
  //         "jobId": widget.jobId,
  //         "callerName": "Client",
  //         "type": "voice_call",
  //         "goToCollection": "workers"
  //       }),
  //     );
  //   } catch (e) {
  //     debugPrint("FCM Notification Error: $e");
  //   }
  // }

  Future<void> _startCallSequence() async {
    // 1. Notify the worker
    // await _sendCallNotification();
    // 2. Initialize Agora
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();

    await _engine.initialize(const RtcEngineContext(
      appId: tempAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("CLIENT SUCCESS: Joined ${connection.channelId}");
        setState(() => _joined = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint("WORKER JOINED: $remoteUid");
      },
      onUserOffline: (connection, remoteUid, reason) => _leaveChannel(),
      onError: (err, msg) => debugPrint("AGORA ERROR: $err - $msg"),
    ));

    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    await _engine.joinChannel(
      token: tempToken,
      channelId: staticChannelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> _handleTranslation() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isTranslating = true);

      // 1. Use a proper temporary path for cross-platform reliability
      final directory = await Directory.systemTemp.path;
      final filePath = '$directory/live_translate.wav';

      final config = const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 16000 // Better for AI Speech-to-Text
      );

      await _audioRecorder.start(config, path: filePath);
      await Future.delayed(const Duration(seconds: 4));
      final path = await _audioRecorder.stop();

      if (path != null) {
        final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/translate-call");

        var request = http.MultipartRequest('POST', url);

        // --- ADD THESE FIELDS FOR YOUR NEW AI WORKFLOW ---
        request.fields['uid'] = widget.workerId; // The ID n8n needs for Firestore
        request.fields['type'] = 'client';      // Identify the role
        request.fields['translate_to'] = 'hi';  // Language preference

        request.files.add(await http.MultipartFile.fromPath(
          'audio_to_translate',
          path,
          contentType: http.MediaType('audio', 'wav'), // Helps n8n parse it correctly
        ));

        try {
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          debugPrint("Status Code: ${response.statusCode}");

          if (response.statusCode == 200) {
            await _audioPlayer.play(
                BytesSource(response.bodyBytes, mimeType: 'audio/wav'),
                mode: PlayerMode.lowLatency
            );
          } else {
            debugPrint("Server Error: ${response.body}");
          }
        } catch (e) {
          debugPrint("Network/Webhook Error: $e");
        }
      }
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _leaveChannel() async {
    await _engine.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.release();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 20),
          Text(widget.workerName, style: const TextStyle(color: Colors.white, fontSize: 24)),
          Text(_joined ? "Connected (Test Mode)" : "Calling Worker...",
              style: TextStyle(color: _joined ? Colors.greenAccent : Colors.white70)),
          const SizedBox(height: 60),

          ElevatedButton.icon(
            onPressed: _isTranslating ? null : _handleTranslation,
            icon: _isTranslating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.translate),
            label: Text(_isTranslating ? "Translating..." : "Live Translation"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white, size: 32),
                onPressed: () {
                  _engine.muteLocalAudioStream(!_muted);
                  setState(() => _muted = !_muted);
                },
              ),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: _leaveChannel,
                child: const Icon(Icons.call_end, size: 32),
              ),
            ],
          )
        ],
      ),
    );
  }
}