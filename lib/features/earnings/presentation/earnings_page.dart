import 'package:flutter/material.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/extensions/context_extensions.dart';
import 'package:voicesewa_worker/features/earnings/presentation/widgets/earnings_chart.dart';
import 'package:voicesewa_worker/features/earnings/presentation/widgets/earnings_summary.dart';
import 'package:voicesewa_worker/features/earnings/presentation/widgets/transaction_history.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Line chart — earnings over time ──────────────────────────
            EarningsChart(),

            const SizedBox(height: 20),

            // ── Summary card — total earned + pending + jobs done ────────
            EarningsSummary(),

            const SizedBox(height: 24),

            // ── Transaction history header ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    context.loc.recentTransactions,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ColorConstants.textDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Real transaction list from Firestore ─────────────────────
            TransactionHistory(),
          ],
        ),
      ),
    );
  }
}
