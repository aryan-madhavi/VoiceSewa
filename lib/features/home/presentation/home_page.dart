import 'package:flutter/material.dart';
import 'package:voicesewa_worker/features/home/presentation/widgets/insights_widget.dart';
import 'package:voicesewa_worker/features/home/presentation/widgets/rating.dart';

import '../../../core/constants/color_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [InsightsWidget(), SizedBox(height: 24), Rating()],
          ),
        ),
      ),
    );
  }
}
