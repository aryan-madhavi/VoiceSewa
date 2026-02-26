import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallPage extends StatefulWidget {
  final String channelId;
  final String clientName;

  const VoiceCallPage({super.key, required this.channelId, required this.clientName});

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  late RtcEngine _engine;
  bool _joined = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: "", //Insert Agora API key from Drive
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
      token: "", // Insert Temp Token from Drive
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
    await _engine.stopAudioMixing();
    await _engine.muteLocalAudioStream(true);

    setState(() {
      _joined = false;
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _leaveChannel(); // Triggers cleanup logic
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 20),
            Text(widget.clientName, style: const TextStyle(color: Colors.white, fontSize: 24)),
            Text(_joined ? "Connected" : "Calling...", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  onPressed: () {
                    _engine.muteLocalAudioStream(!_muted);
                    setState(() => _muted = !_muted);
                  },
                ),
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: _leaveChannel,
                  child: const Icon(Icons.call_end),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}