import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voicesewa_client/features/voicebot/models/chat_message.dart';

class AudioBubble extends ConsumerStatefulWidget {
  final ChatMessage message;

  const AudioBubble({super.key, required this.message});

  @override
  ConsumerState<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends ConsumerState<AudioBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isLoaded = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final path = widget.message.audioPath;
    if (path == null) return;

    // Retry up to 3s — bot response file may still be writing when bubble builds
    for (int i = 0; i < 15; i++) {
      if (File(path).existsSync()) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!File(path).existsSync()) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      await _player.setAudioSource(AudioSource.file(path));

      _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _player.playerStateStream.listen((ps) {
        if (!mounted) return;
        setState(() {
          _isPlaying =
              ps.playing && ps.processingState != ProcessingState.completed;
          if (ps.processingState == ProcessingState.completed) {
            _position = Duration.zero;
            _player.seek(Duration.zero);
          }
        });
      });

      if (mounted) setState(() => _isLoaded = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        isUser ? colorScheme.primaryContainer : colorScheme.secondaryContainer;
    final fgColor = isUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Text ─────────────────────────────────────────────────
            if (widget.message.text != null &&
                widget.message.text!.isNotEmpty) ...[
              Text(
                widget.message.text!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: fgColor),
              ),
              const SizedBox(height: 8),
            ],

            // ── Audio player ─────────────────────────────────────────
            if (widget.message.audioPath != null)
              _buildAudioPlayer(fgColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(Color fgColor) {
    // Error state
    if (_hasError) {
      return Text(
        '⚠ Audio unavailable',
        style: TextStyle(color: fgColor, fontSize: 12),
      );
    }

    // Loading state — file still being written
    if (!_isLoaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(color: fgColor, fontSize: 12),
          ),
        ],
      );
    }

    // Ready state
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fgColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: fgColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Seekbar + duration
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: fgColor,
                  inactiveTrackColor: fgColor.withOpacity(0.25),
                  thumbColor: fgColor,
                ),
                child: Slider(
                  min: 0,
                  max: _duration.inMilliseconds
                      .toDouble()
                      .clamp(1, double.infinity),
                  value: _position.inMilliseconds.toDouble().clamp(
                        0,
                        _duration.inMilliseconds
                            .toDouble()
                            .clamp(1, double.infinity),
                      ),
                  onChanged: (v) async {
                    await _player.seek(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: fgColor.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}