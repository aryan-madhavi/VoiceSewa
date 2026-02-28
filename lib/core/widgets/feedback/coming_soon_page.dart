import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/widgets/layout/appbar_widget.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: context.loc.comingSoon),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.loc.comingSoon2, style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
