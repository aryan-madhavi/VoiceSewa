import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/app_constants.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/widgets/navigation/bottom_navbar_widget.dart';
import 'package:voicesewa_client/core/widgets/layout/appbar_widget.dart';

class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final pages = AppConstants.pages;

    return Scaffold(
      appBar: const AppBarWidget(title: StringConstants.appName),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(child: pages[currentTab]![2] as Widget),
    );
  }
}
