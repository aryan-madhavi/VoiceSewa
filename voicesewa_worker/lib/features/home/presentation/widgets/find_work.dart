import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/helper_function.dart';
import '../../../../core/constants/static_data.dart';
import '../../../../core/extensions/context_extensions.dart';

class FindWork extends StatefulWidget {
  const FindWork({super.key});

  @override
  State<FindWork> createState() => _FindWorkState();
}

class _FindWorkState extends State<FindWork> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: workList.map((job) {
        return FindWorkCard(
          job: job,
          onApplyTap: () => print("Applied to ${job.title}"),
          onViewDetailsTap: () => print("View details of ${job.title}"),
        );
      }).toList(),
    );
  }
}

class FindWorkCard extends StatelessWidget {
  final WorkPostData job;
  final VoidCallback onApplyTap;
  final VoidCallback onViewDetailsTap;

  const FindWorkCard({
    super.key,
    required this.job,
    required this.onApplyTap,
    required this.onViewDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22.0, 16.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job.priceRange,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ColorConstants.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  if (job.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.tags.map((tag) => findWorkBuildTag(tag)).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            job.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: ColorConstants.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: findWorkBuildIconText(
                          Icons.location_on_outlined,
                          "${job.location} • ${job.distance}",
                        ),
                      ),
                      findWorkBuildIconText(Icons.access_time, job.timePosted),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApplyTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: Text(
                              context.loc.applyNow,// "Apply Now",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              )
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewDetailsTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConstants.textDark,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                              context.loc.viewDetails,  // "View Details"
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                color: ColorConstants.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }


}