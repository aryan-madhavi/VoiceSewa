import 'package:flutter/material.dart';
import 'package:voicesewa_client/providers/model/booking_model.dart';

class JobDetailsSheet extends StatelessWidget {
  final BookingModel job;
  const JobDetailsSheet({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Icon(job.serviceIcon, color: job.serviceColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  job.serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(job.workerName),
              subtitle: Text("Rating: ${job.workerRating.toStringAsFixed(1)} ★"),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text("Date"),
              subtitle: Text(job.formattedDate),
            ),
            if (job.eta != null)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text("ETA"),
                subtitle: Text(job.eta!),
              ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Amount"),
              subtitle: Text("₹${job.amount.toStringAsFixed(0)}"),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in_outlined),
              title: const Text("Status"),
              subtitle: Text(
                job.status,
                style: TextStyle(
                  color: job.statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (job.userRating != null)
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text("Your Rating"),
                subtitle: Text("${job.userRating!.toStringAsFixed(1)} / 5"),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
