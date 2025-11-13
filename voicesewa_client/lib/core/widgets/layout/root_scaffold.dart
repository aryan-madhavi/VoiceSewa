import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_client/core/constants/app_constants.dart';
import 'package:voicesewa_client/core/constants/string_constants.dart';
import 'package:voicesewa_client/core/routes/navigation_routes.dart';
import 'package:voicesewa_client/core/widgets/navigation/bottom_navbar_widget.dart';
import 'package:voicesewa_client/core/widgets/layout/appbar_widget.dart';
import 'package:voicesewa_client/core/providers/navbar_page_provider.dart';

class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final routeName = AppConstants.pages[currentTab]![2] as String;

    /// Look up the WidgetBuilder from AppRoutes
    final builder = AppRoutes.routes[routeName];

    if (builder == null) {
      // Fallback in case the route is missing
      return const Scaffold(
        body: Center(child: Text('Page not found')),
      );
    }

    return Scaffold(
      appBar: const AppBarWidget(title: StringConstants.appName),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: builder(context), 
      ),
    );
  }
}
