import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/providers/model/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onPlayVoice;

  const WorkerCard({Key? key, required this.worker, required this.onPlayVoice})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile photo
            (worker.photoUrl != '')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      worker.photoUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.person, size: 64),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Verified
                  Row(
                    children: [
                      Text(
                        worker.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (worker.verified)
                        const Icon(
                          Icons.verified,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Rating & distance
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                      Text(
                        ' ${worker.rating}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      Text(
                        worker.distance,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(
                    worker.priceRange,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Voice playback
            IconButton(
              onPressed: onPlayVoice,
              icon: const Icon(
                Icons.play_circle_fill,
                color: ColorConstants.seed,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
