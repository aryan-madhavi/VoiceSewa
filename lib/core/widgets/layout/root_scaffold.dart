import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/database/app_database.dart';
import 'package:voicesewa_worker/core/widgets/navigation/bottom_navbar_widget.dart';
import 'package:voicesewa_worker/core/widgets/layout/appbar_widget.dart';
import 'package:voicesewa_worker/features/sync/providers/sync_providers.dart';
import '../../constants/app_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../providers/navbar_page_provider.dart';

class RootScaffold extends ConsumerWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navTabProvider);
    final pages = AppConstants.getPages(context);
    final userId = WorkerDatabase.currentUserId;
    if (userId != null) {
      ref.watch(syncServiceProvider(userId));
    }

    return Scaffold(
      appBar: AppBarWidget(title: context.loc.appName),
      bottomNavigationBar: BottomNavBar(),
      body: pages[currentTab]![2] as Widget,
    );
  }
}
