import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/bottom_navbar_widget.dart';
import 'package:voicesewa_client/core/widgets/appbar_widget.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: const BottomNavBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () {},
        tooltip: 'Speak',
        child: const Icon(Icons.mic),
      ),
    );
  }
}