import 'package:flutter/material.dart';
import 'package:voicesewa_worker/widgets/core/appbar_widget.dart';
import 'package:voicesewa_worker/widgets/core/coming_soon_widget.dart';

class ComingSoonPage extends StatelessWidget {
  
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Coming Soon'),
      body: ComingSoon()
    );
  }
}
