import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/support_button.dart';
import 'package:voicesewa_client/features/settings/presentation/widgets/voice_helpbot_section.dart';
import 'package:voicesewa_client/features/settings/providers/support_provider.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voicePrompt = ref.watch(voiceHelpProvider);
    final selectedIssue = ref.watch(selectedIssueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            context.loc.supportAndHelp, // "Support & Help"
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            VoiceHelpBotSection(voicePrompt: voicePrompt),

            const SizedBox(height: 24),

            Text(
              context.loc.quickAssistance, // "Quick Assistance",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 12),

            SupportButton(
              label: context.loc.paymentIssue,  //"Payment issue",
              icon: Icons.payment_outlined,
              isSelected: selectedIssue == context.loc.paymentIssue,
              onTap: () => ref.read(selectedIssueProvider.notifier).state = context.loc.paymentIssue,
            ),
            SupportButton(
              label: context.loc.workerNotArrived,  //"Worker not arrived",
              icon: Icons.person_off_outlined,
              isSelected: selectedIssue == context.loc.workerNotArrived,
              onTap: () => ref.read(selectedIssueProvider.notifier).state = context.loc.workerNotArrived,
            ),
            SupportButton(
              label: context.loc.cancelJob, //"Cancel job",
              icon: Icons.cancel_outlined,
              isSelected: selectedIssue == "Cancel job",
              onTap: () => ref.read(selectedIssueProvider.notifier).state = "Cancel job",
            ),
            SupportButton(
              label: context.loc.fAQs,  //"FAQs",
              icon: Icons.help_outline,
              isSelected: selectedIssue == context.loc.fAQs,
              onTap: () => ref.read(selectedIssueProvider.notifier).state = context.loc.fAQs,
            ),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _openChatSupport(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  context.loc.chatWithSupport, // "Chat with Support"
                ),
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
        title: Text(
          context.loc.chatWithSupport, // "Chat with Support"
        ),
        content: Text(
            context.loc.chatFunctionalityComingSoon, //"Chat functionality coming soon!"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.loc.oK, //"OK"
            ),
          ),
        ],
      ),
    );
  }
}
