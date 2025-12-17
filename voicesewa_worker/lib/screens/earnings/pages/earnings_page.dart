import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/screens/earnings/cards/monthly_goal.dart';
import 'package:voicesewa_worker/screens/earnings/cards/transactionhistory.dart';
import 'package:voicesewa_worker/screens/earnings/cards/withdraw.dart';

import '../../../extensions/context_extensions.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children:[
            const SizedBox(height: 20,),

            const MonthlyGoal(),

            const SizedBox(height: 20,),

            const Withdraw(),

            const SizedBox(height: 24,),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    context.loc.recentTransactions, // "Recent Transactions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ColorConstants.textDark,
                    ),
                  ),
                  TextButton(
                      onPressed: (){},
                      child: Text(
                        context.loc.seeAll, // "See All"
                      ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8,),

            const TransactionHistory(),
          ],
        ),
      ),
    );
  }
}