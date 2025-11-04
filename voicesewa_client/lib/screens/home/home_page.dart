import 'package:flutter/material.dart';
import 'package:voicesewa_client/widgets/home/quick_actions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}
