import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/extensions/context_extensions.dart'; // Assuming this exists

final voiceHelpProvider = StateProvider<String?>((ref) => null);
final selectedIssueProvider = StateProvider<String?>((ref) => null);

class VoiceBotScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceText = ref.watch(voiceHelpProvider);
    final textToShow = voiceText ?? context.loc.speakWhatIsTheProblem;

    return Text(textToShow);
  }
}