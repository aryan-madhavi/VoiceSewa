import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/features/support/presentation/widgets/support_button.dart';
import 'package:voicesewa_client/features/support/presentation/widgets/voice_helpbot_section.dart';
import 'package:voicesewa_client/features/support/providers/support_provider.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voicePrompt = ref.watch(voiceHelpProvider);
    final selectedIssue = ref.watch(selectedIssueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support & Help"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            VoiceHelpBotSection(voicePrompt: voicePrompt),

            const SizedBox(height: 24),

            Text(
              "Quick Assistance",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 12),

            SupportButton(
              label: "Payment issue",
              icon: Icons.payment_outlined,
              isSelected: selectedIssue == "Payment issue",
              onTap: () => ref.read(selectedIssueProvider.notifier).state = "Payment issue",
            ),
            SupportButton(
              label: "Worker not arrived",
              icon: Icons.person_off_outlined,
              isSelected: selectedIssue == "Worker not arrived",
              onTap: () => ref.read(selectedIssueProvider.notifier).state = "Worker not arrived",
            ),
            SupportButton(
              label: "Cancel job",
              icon: Icons.cancel_outlined,
              isSelected: selectedIssue == "Cancel job",
              onTap: () => ref.read(selectedIssueProvider.notifier).state = "Cancel job",
            ),
            SupportButton(
              label: "FAQs",
              icon: Icons.help_outline,
              isSelected: selectedIssue == "FAQs",
              onTap: () => ref.read(selectedIssueProvider.notifier).state = "FAQs",
            ),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openChatSupport(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Chat with Support"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Chat with Support"),
        content: const Text("Chat functionality coming soon!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
