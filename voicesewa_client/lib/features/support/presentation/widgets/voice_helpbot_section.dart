import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';

class VoiceHelpBotSection extends StatelessWidget {
  final String voicePrompt;

  const VoiceHelpBotSection({super.key, required this.voicePrompt});

  @override
  Widget build(BuildContext context) {
    
    return Card(
      color: ColorConstants.navBar,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: ColorConstants.floatingActionButton,
              child: Icon(Icons.mic, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                voicePrompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
