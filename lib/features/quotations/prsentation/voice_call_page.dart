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
  final String workerName;
  final String workerId;
  final String jobId;

  const VoiceCallPage({
    super.key,
    required this.channelId,
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
    _startCall();
  }

  Future<void> _sendCallNotification(String workerId, String jobId) async {
    final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/call-notification");
    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "receiverId": workerId,
          "jobId": jobId,
          "callerName": "Client",
          "type": "voice_call",
          "goToCollection": "workers"
        }),
      );
    } catch (e) {
      debugPrint("FCM Notification Error: $e");
    }
  }

  Future<void> _startCall() async {
    await _sendCallNotification(widget.workerId, widget.jobId);
    _initAgora();
  }

  Future<void> _handleTranslation() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() => _isTranslating = true);

      final config = const RecordConfig(encoder: AudioEncoder.wav);
      await _audioRecorder.start(config, path: 'live_translate.wav');
      await Future.delayed(const Duration(seconds: 5));
      final path = await _audioRecorder.stop();

      if (path != null) {
        final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/translate-call");
        var request = http.MultipartRequest('POST', url);
        request.fields['translate_to'] = 'hi';
        request.files.add(await http.MultipartFile.fromPath('audio_to_translate', path));

        try {
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            await _audioPlayer.play(BytesSource(response.bodyBytes), mode: PlayerMode.lowLatency);
          }
        } catch (e) {
          debugPrint("Translation Webhook Error: $e");
        }
      }
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: "YOUR_AGORA_ID"));

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) => setState(() => _joined = true),
      onUserOffline: (connection, remoteUid, reason) => _leaveChannel(),
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
          Text(_joined ? "Connected" : "Calling...", style: const TextStyle(color: Colors.white70)),
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