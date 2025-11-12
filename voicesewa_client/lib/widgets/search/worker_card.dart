import 'package:flutter/material.dart';
import 'package:voicesewa_client/constants/core/color_constants.dart';
import 'package:voicesewa_client/providers/data/home/services.dart';
import 'package:voicesewa_client/providers/model/worker_model.dart';
import 'package:voicesewa_client/widgets/search/worker_details_sheet.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onPlayVoice;

  const WorkerCard({Key? key, required this.worker, required this.onPlayVoice})
    : super(key: key);

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerDetailsSheet(
        worker: worker,
        onBookNow: () {
          Navigator.pop(context);
          // TODO: handle booking logic here
        },
        onPlayVoice: onPlayVoice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Photo ---
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: worker.photoUrl.isNotEmpty
                    ? Image.network(
                        worker.photoUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : CircleAvatar(
                        radius: 35,
                        backgroundColor: worker.serviceColor,
                        child: Icon(
                          worker.serviceIcon,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(width: 14),

              // --- Worker Info ---
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
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
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

                    // Rating + Distance
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${worker.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        Text(
                          worker.distance,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Price Range
                    Text(
                      worker.priceRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /* // Skills (show up to 3)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: worker.skills!
                          .take(3)
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ), */

                    const SizedBox(height: 6),

                    // Experience + Availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${worker.experience} yrs experience',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              worker.available!
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: worker.available!
                                  ? Colors.green
                                  : Colors.red,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              worker.available! ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                color: worker.available!
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- Voice Button ---
              IconButton(
                onPressed: onPlayVoice,
                tooltip: "Play voice intro",
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: ColorConstants.seed,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
