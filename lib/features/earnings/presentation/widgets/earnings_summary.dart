import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicesewa_worker/core/constants/color_constants.dart';
import 'package:voicesewa_worker/core/constants/helper_function.dart';
import 'package:voicesewa_worker/core/constants/string_constants.dart';
import 'package:voicesewa_worker/features/earnings/providers/earnings_provider.dart';

/// Shows total earned + pending amount cards.
/// Withdraw button removed as per requirements.
class EarningsSummary extends ConsumerWidget {
  const EarningsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsDataProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: earningsAsync.when(
        loading: () => _buildCard(
          context,
          totalEarned: 0,
          pendingAmount: 0,
          isLoading: true,
        ),
        error: (_, __) => _buildCard(context, totalEarned: 0, pendingAmount: 0),
        data: (data) => _buildCard(
          context,
          totalEarned: data.totalEarned,
          pendingAmount: data.pendingAmount,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required double totalEarned,
    required double pendingAmount,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0056D2), Color(0xFF003C9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
                  height: 42,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Text(
                  '${StringConstants.rupee}${totalEarned.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pending — scheduled/inProgress jobs (quotation amount)
              withdrawBuildStatCard(
                'Pending',
                isLoading
                    ? '—'
                    : '${StringConstants.rupee}${pendingAmount.toInt()}',
                Colors.orange,
              ),
              const SizedBox(width: 12),
              // Completed jobs count
              _completedCountCard(isLoading),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completedCountCard(bool isLoading) {
    if (isLoading) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jobs Done',
                style: TextStyle(color: ColorConstants.textGrey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final count =
            ref
                .watch(earningsDataProvider)
                .whenOrNull(data: (d) => d.billedJobs.length) ??
            0;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jobs Done',
                  style: TextStyle(
                    color: ColorConstants.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
