import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/static_data.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20),

      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 60,
      ),
      itemCount: staticTransactions.length,
      itemBuilder: (context, index){
        final txn = staticTransactions[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: txn.isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: txn.isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          title: Text(
            txn.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            "${txn.date} . ${txn.status}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          trailing: Text(
            "${txn.isCredit ? '+':'-'} ${txn.amount}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: txn.isCredit ? Colors.green[700] : ColorConstants.textDark,
            ),
          ),
        );
      },
    );
  }
}
