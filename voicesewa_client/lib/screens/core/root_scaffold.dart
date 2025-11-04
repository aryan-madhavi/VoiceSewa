import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/constants/core/app_constants.dart';
import 'package:voicesewa_client/constants/core/string_constants.dart';
import 'package:voicesewa_client/widgets/core/bottom_navbar_widget.dart';
import 'package:voicesewa_client/widgets/core/appbar_widget.dart';
import 'package:voicesewa_client/providers/navbar_page_provider.dart';

class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final pages = AppConstants.pages;

    return Scaffold(
      appBar: const AppBarWidget(title: StringConstants.appName),
      bottomNavigationBar: BottomNavBar(),
      body: pages[currentTab]![2] as Widget,
    );
  }
}