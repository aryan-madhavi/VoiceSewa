import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/constants/core/static_data.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';

import '../../../constants/core/helper_function.dart';
import '../../../extensions/context_extensions.dart';

class Withdraw extends StatefulWidget {
  const Withdraw({super.key});

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0056D2), Color(0xFF003C9E)],
                begin: Alignment.topLeft,
                  end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  context.loc.availableForWithdrawal, // "Available for Withdrawal",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 8,),

                Text(
                  "${StringConstants.rupee}${(withdrawalAmount).toInt()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20,),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColorConstants.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12,),
                    ),
                      child: Text(
                        context.loc.withdrawMoney, // "Withdraw Money",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ),
                ),
                const SizedBox(height: 16,),
                Row(
                  children: [
                    withdrawBuildStatCard(
                        context.loc.pending, // "Pending",
                        "${StringConstants.rupee}${(pendingAmount).toInt()}",
                        Colors.orange),
                    const SizedBox(width: 12,),
                    withdrawBuildStatCard(
                        context.loc.totalEarned, // "Total Earned",
                        "${StringConstants.rupee}${(totalAmountEarned).toInt()}",
                        Colors.green)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

