import 'package:flutter_riverpod/legacy.dart';

/// Define the tabs
enum NavTab { home, search, speak, history, settings }

/// StateNotifier for managing the currently selected bottom nav tab
class NavTabNotifier extends StateNotifier<NavTab> {
  NavTabNotifier() : super(NavTab.home);

  /// Set the current tab
  void setTab(NavTab tab) => state = tab;

  /// Optional: reset to default tab
  void reset() => state = NavTab.home;
}

/// Riverpod provider for the bottom nav tab
final navTabProvider = StateNotifierProvider.autoDispose<NavTabNotifier, NavTab>(
  (ref) => NavTabNotifier(),
);