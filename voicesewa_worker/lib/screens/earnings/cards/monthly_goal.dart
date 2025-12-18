import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/static_data.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';

import '../../../constants/core/color_constants.dart';
import '../../../extensions/context_extensions.dart';

class MonthlyGoal extends StatefulWidget {
  const MonthlyGoal({super.key});

  @override
  State<MonthlyGoal> createState() => _MonthlyGoalState();
}

class _MonthlyGoalState extends State<MonthlyGoal> {
  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.loc.monthlyGoal, // "Monthly Goal",
                  style: TextStyle(
                    color: ColorConstants.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16,),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: ColorConstants.primaryBlue,
              ),
            ),

            const SizedBox(height: 12,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${StringConstants.rupee}${currentEarnings.toInt()}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12,),

            Row(
              children: [
                const Icon(
                  Icons.bolt,
                  color: Colors.amber,
                  size: 18,
                ),

                const SizedBox(width: 4,),

                Expanded(
                  child: Text(
                    "${context.loc.youRe} ${(progress * 100).toInt()}% ${context.loc.thereKeepItUp}",
                    style: TextStyle(
                      color: ColorConstants.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
