import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/providers/model/worker_model.dart';

class WorkerDetailsSheet extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onBookNow;
  final VoidCallback? onPlayVoice;

  const WorkerDetailsSheet({
    Key? key,
    required this.worker,
    this.onBookNow,
    this.onPlayVoice,
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
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${worker.rating.toStringAsFixed(1)}'),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          Text(worker.distance, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        worker.priceRange,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onPlayVoice,
                  icon: const Icon(Icons.play_circle_fill,
                      size: 40, color: ColorConstants.seed),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),

            // --- Experience & Availability ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${worker.experience} yrs Experience',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                Row(
                  children: [
                    Icon(
                      worker.available! ? Icons.circle : Icons.circle_outlined,
                      color: worker.available! ? Colors.green : Colors.red,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      worker.available! ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 13,
                        color: worker.available! ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Skills Section ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Skills',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: worker.skills!
                  .map((skill) => Chip(
                        label: Text(skill),
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: const TextStyle(color: Colors.black87),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // --- Voice Intro ---
            if (worker.voiceText.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: ColorConstants.seed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: ColorConstants.seed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        worker.voiceText,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

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
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  'Book Now',
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