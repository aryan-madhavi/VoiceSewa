import 'package:flutter_riverpod/legacy.dart';
import 'package:voicesewa_client/constants/core/app_constants.dart';

class NavTabNotifier extends StateNotifier<NavTab> {
  NavTabNotifier() : super(NavTab.home);

  void setTab(NavTab tab) {
    state = tab;
  }
}

final navTabProvider = StateNotifierProvider<NavTabNotifier, NavTab>(
  (ref) => NavTabNotifier(),
);