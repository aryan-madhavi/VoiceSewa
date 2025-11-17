import 'package:flutter/material.dart';
import 'package:voicesewa_worker/screens/earnings/cards/monthly_goal.dart';
import 'package:voicesewa_worker/screens/earnings/cards/transactionhistory.dart';
import 'package:voicesewa_worker/screens/earnings/cards/withdraw.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children:[
            MonthlyGoal(),
            Withdraw(),
            Text("Recent Transactions"),
            TransactionHistory(),
          ],
        ),
      ),
    );
  }
}