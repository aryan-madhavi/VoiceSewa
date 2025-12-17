import 'package:flutter/material.dart';

import '../../extensions/context_extensions.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${context.loc.comingSoon} ......",// "Coming Soon ......",
              style: TextStyle(fontSize: 20)
            ),
          ],
        ),
      ],
    );
  }
}
