import 'package:flutter/material.dart';
import 'package:voicesewa_client/widgets/home/quick_actions.dart';
import 'package:voicesewa_client/widgets/home/quick_book.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
