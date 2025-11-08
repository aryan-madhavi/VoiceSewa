import 'package:flutter_riverpod/legacy.dart';

/// Voice prompt provider
final voiceHelpProvider = StateProvider<String>((ref) => "Boliye, kya samasya hai?");

/// Currently selected issue provider
final selectedIssueProvider = StateProvider<String?>((ref) => null);
