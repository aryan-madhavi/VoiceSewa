import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceCallPage extends StatefulWidget {
  final String channelId;
  final String clientName;

  const VoiceCallPage({super.key, required this.channelId, required this.clientName});

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
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Agora requires microphone permission
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "YOUR_AGORA_APP_ID",
    ));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        setState(() => _joined = true);
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        _leaveChannel();
      },
    ));

    await _engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioGameStreaming,
    );

    await _engine.joinChannel(
      token: "YOUR_TEMP_TOKEN",
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> _handleTranslation() async {
    try {
      // Fixed: hasPermission now properly recognized after 'flutter run'
      if (await _audioRecorder.hasPermission()) {
        setState(() => _isTranslating = true);

        // Record a 4-second chunk of the conversation
        const config = RecordConfig(encoder: AudioEncoder.wav);
        await _audioRecorder.start(config, path: 'worker_live.wav');
        await Future.delayed(const Duration(seconds: 4));
        final path = await _audioRecorder.stop();

        if (path != null) {
          // Hits your translate-call webhook
          final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/translate-call");
          var request = http.MultipartRequest('POST', url);
          request.fields['translate_to'] = 'hi';
          request.files.add(await http.MultipartFile.fromPath('audio_to_translate', path));

          var response = await http.Response.fromStream(await request.send());
          if (response.statusCode == 200) {
            // Plays the Sarvam AI translated voice back to the worker
            await _audioPlayer.play(BytesSource(response.bodyBytes), mode: PlayerMode.lowLatency);
          }
        }
      }
    } catch (e) {
      debugPrint("Translation Error: $e");
    } finally {
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
          Text(widget.clientName, style: const TextStyle(color: Colors.white, fontSize: 24)),
          Text(_joined ? "Connected" : "Incoming Call...", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 60),

          ElevatedButton.icon(
            onPressed: _isTranslating ? null : _handleTranslation,
            icon: _isTranslating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.translate),
            label: Text(_isTranslating ? "Translating..." : "Translate Client"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
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