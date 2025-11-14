import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/widgets/home/quick_actions.dart';
import 'package:voicesewa_client/providers/speech_to_text_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speechState = ref.watch(speechProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Add spacing at top when overlay is visible
                if (speechState.isListening || speechState.recognizedText.isNotEmpty)
                  SizedBox(height: 200),
                
                // Quick Actions
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      QuickActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating voice recognition overlay - shows when listening or has text
          if (speechState.isListening || speechState.recognizedText.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: speechState.isListening
                          ? [Colors.red[400]!, Colors.red[600]!]
                          : [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (speechState.isListening ? Colors.red : Colors.blue)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Animated microphone icon
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      speechState.isListening
                                          ? 'Listening'
                                          : 'Voice Recognition',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Animated dots when listening
                                    if (speechState.isListening) ...[
                                      SizedBox(width: 4),
                                      _AnimatedDots(),
                                    ],
                                  ],
                                ),
                                if (speechState.isListening)
                                  Text(
                                    'Speak now - Release to stop',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Close button when not listening
                          if (!speechState.isListening && 
                              speechState.recognizedText.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () {
                                ref.read(speechProvider.notifier).clearText();
                              },
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                            ),
                        ],
                      ),
                      
                      // Real-time recognized text display
                      SizedBox(height: 12),
                      Container(
                        constraints: BoxConstraints(minHeight: 60),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.text_fields,
                                  color: speechState.isListening 
                                      ? Colors.red[700] 
                                      : Colors.blue[700],
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  speechState.isListening 
                                      ? 'Live Transcription:' 
                                      : 'Recognized Text:',
                                  style: TextStyle(
                                    color: speechState.isListening 
                                        ? Colors.red[700] 
                                        : Colors.blue[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: Text(
                                speechState.recognizedText.isEmpty
                                    ? (speechState.isListening 
                                        ? 'Start speaking...' 
                                        : 'No text recognized')
                                    : speechState.recognizedText,
                                key: ValueKey(speechState.recognizedText),
                                style: TextStyle(
                                  color: speechState.recognizedText.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.black87,
                                  fontSize: 18,
                                  height: 1.5,
                                  fontWeight: speechState.recognizedText.isEmpty
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Error display
                      if (speechState.error != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  speechState.error!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Animated dots widget for listening indicator
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dotCount = (_controller.value * 4).floor() % 4;
        return Text(
          '.' * dotCount,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        );
      },
    );
  }
}