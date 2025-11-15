import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/layout/appbar_widget.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Coming Soon'),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Coming Soon ......", style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
