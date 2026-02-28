import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';

class WorkerDetailsSheet extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onBookNow;
  final String? distanceLabel;

  const WorkerDetailsSheet({
    Key? key,
    required this.worker,
    this.onBookNow,
    this.distanceLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // --- Drag handle ---
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // --- Profile Header ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: worker.photoUrl.isNotEmpty
                      ? Image.network(
                          worker.photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Verified
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (worker.verified)
                            const Icon(
                              Icons.verified,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Rating + Distance
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${worker.rating.toStringAsFixed(1)}'),
                          if (distanceLabel != null) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 16,
                            ),
                            Text(
                              distanceLabel!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Service label
                      Text(
                        worker.serviceLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: worker.serviceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // --- Availability ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  worker.available == true
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: worker.available == true ? Colors.green : Colors.red,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  worker.available == true ? context.loc.available : context.loc.unavailable,
                  style: TextStyle(
                    fontSize: 13,
                    color: worker.available == true ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Skills Section ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.loc.skills,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (worker.skills ?? [])
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: const TextStyle(color: Colors.black87),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  )
                  .toList(),
            ),

            // --- Bio ---
            if (worker.bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                worker.bio,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],

            const SizedBox(height: 24),

            // --- Book Now Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBookNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.seed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: Text(
                  context.loc.bookNow,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
