import 'package:flutter/material.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children:[
          Row(
            children:[
              Text("Task Name - Client Name / Bonus / Transfer to Bank"),
              Text("+/- Rs XXXX"),
            ],
          ),
          Row(
            children:[
              Text("Day,Time, Date"),
              Text("Job Completed / Bonus Earned / Withdraw Processed"),
            ],
          ),
        ],
      ),
    );
  }
}