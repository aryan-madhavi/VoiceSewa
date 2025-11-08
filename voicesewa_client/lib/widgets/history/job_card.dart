import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/constants/core/helper_functions.dart';
import 'package:voicesewa_client/widgets/history/status_badge.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final String status = job['status'];
    final Color statusColor = Helpers.getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  job['service'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatusBadge(status: status, color: statusColor),
              ],
            ),

            const SizedBox(height: 10),

            // --- Worker Name + Date ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job['worker'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (job['rating'] != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        "${job['rating']}",
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  job['date'],
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --- Footer Row: Rating + Amount ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      "Your Rating: ${job['userRating'] ?? '–'}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  job['amount'],
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const Divider(height: 20, color: Colors.grey),

            // --- Buttons Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Book Again"),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.seed,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Invoice"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text("Details"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
