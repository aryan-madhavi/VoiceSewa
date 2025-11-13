import 'package:flutter/material.dart';
import 'package:voicesewa_client/features/home/presentation/widgets/quick_actions.dart';
import 'package:voicesewa_client/features/home/presentation/widgets/quick_book.dart';
import 'package:voicesewa_client/features/home/presentation/widgets/recent_requests.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              QuickActionsGrid(),
              QuickBookCard(),
              RecentRequestCard(),
            ],
          ),
        ),
      ),
    );
  }
}
