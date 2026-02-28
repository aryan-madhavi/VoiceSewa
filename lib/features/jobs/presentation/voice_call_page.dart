import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

const String tempAppId = "e7f6e9aeecf14b2ba10e3f40be9f56e7";
const String tempToken = "007eJxTYND87Zb0c+N/vResb0pl/mUKGMyXnSHqumXqVvmMBQd/9E1WYEhONEg2STUxNU9ONjexTE5LSkkyMjE0SzIwMUgzM0010124KLMhkJFh1+Z+FkYGCATxORlKUotL4pMTc3IYGABY+iMB";
const String staticChannelName = "test_call";


class VoiceCallPage extends StatefulWidget {
  final String clientName;

  const VoiceCallPage({super.key, required this.clientName});

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
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Microphone permission denied");
        return;
      }

      _engine = createAgoraRtcEngine();

      await _engine.initialize(const RtcEngineContext(
        appId: tempAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 3. Register Event Handlers BEFORE joining or calling audio methods
      _engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("SUCCESS: Joined channel: ${connection.channelId}");

          // SAFE ZONE: Hardware is now ready for audio adjustments
          _engine.setEnableSpeakerphone(true);

          if (mounted) setState(() => _joined = true);
        },
        onConnectionStateChanged: (connection, state, reason) {
          debugPrint("CONNECTION STATE: $state REASON: $reason");
        },
        onUserJoined: (connection, remoteUid, int elapsed) {
          debugPrint("REMOTE USER JOINED: $remoteUid");
        },
        onUserOffline: (connection, remoteUid, reason) => _leaveChannel(),
        onError: (ErrorCodeType err, String msg) {
          debugPrint("AGORA ERROR: $err - $msg");
        },
      ));

      // 4. Set Audio Profile
      await _engine.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // 5. Join Channel
      // Note: enableAudio() is omitted to prevent the -3 "Not Ready" error
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
    } catch (e) {
      debugPrint("Init Agora Error: $e");
    }
  }

// ... _handleTranslation and build methods remain the same ...


  // ... _handleTranslation and _leaveChannel remain the same ...

  Future<void> _handleTranslation() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() => _isTranslating = true);
        const config = RecordConfig(encoder: AudioEncoder.wav);
        await _audioRecorder.start(config, path: 'worker_live.wav');
        await Future.delayed(const Duration(seconds: 4));
        final path = await _audioRecorder.stop();

        if (path != null) {
          final url = Uri.parse("https://fomoha8938hutudns.app.n8n.cloud/webhook/translate-call");
          var request = http.MultipartRequest('POST', url);
          request.fields['translate_to'] = 'hi';
          request.files.add(await http.MultipartFile.fromPath('audio_to_translate', path));

          var response = await http.Response.fromStream(await request.send());
          if (response.statusCode == 200) {
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
          Text(_joined ? "Connected (Test Mode)" : "Connecting to Agora...",
              style: TextStyle(color: _joined ? Colors.greenAccent : Colors.white70)),
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