import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/core/widgets/bottom_navbar_widget.dart';
import 'package:voicesewa_worker/core/widgets/appbar_widget.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(title: StringConstants.appName),
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