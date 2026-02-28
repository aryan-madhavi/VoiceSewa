import 'package:flutter/material.dart';
import 'package:voicesewa_client/core/constants/color_constants.dart';
import 'package:voicesewa_client/core/extensions/context_extensions.dart';
import 'package:voicesewa_client/shared/models/worker_model.dart';
import 'package:voicesewa_client/features/search/presentation/widgets/worker_details_sheet.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final String? distanceLabel;

  const WorkerCard({Key? key, required this.worker, this.distanceLabel})
    : super(key: key);

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkerDetailsSheet(
        worker: worker,
        distanceLabel: distanceLabel,
        onBookNow: () {
          Navigator.pop(context);
          // TODO: handle booking logic here
        },
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
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Text(
                            distanceLabel!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Availability
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          worker.available == true
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: worker.available == true
                              ? Colors.green
                              : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          worker.available == true
                              ? context.loc.available
                              : context.loc.unavailable,
                          style: TextStyle(
                            fontSize: 12,
                            color: worker.available == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
