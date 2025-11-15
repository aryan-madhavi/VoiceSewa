import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';


final darkModeProvider = StateProvider<bool>((ref) => false);
final notificationProvider = StateProvider<bool>((ref) => true);

class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    return Switch(
      value: isDark,
      onChanged: (val) => ref.read(darkModeProvider.notifier).state = val,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class NotificationSwitch extends ConsumerWidget {
  const NotificationSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationProvider);
    return Switch(
      value: enabled,
      onChanged: (val) => ref.read(notificationProvider.notifier).state = val,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
