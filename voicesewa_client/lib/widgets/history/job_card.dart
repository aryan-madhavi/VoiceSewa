import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/constants/core/helper_functions.dart';
import 'package:voicesewa_client/widgets/history/status_badge.dart'; // for getStatusColor

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final String status = job['status'];
    final Color color = Helpers.getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    job['service'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Handle repeat booking
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Repeat Booking"),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.seed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job['date'], style: TextStyle(color: Colors.grey[700])),
                Text(
                  job['amount'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Worker: ${job['worker']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${job['eta']}",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                StatusBadge(status: status, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
