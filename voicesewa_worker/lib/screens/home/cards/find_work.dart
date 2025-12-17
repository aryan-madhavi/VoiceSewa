import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/app_constants.dart';
import 'package:voicesewa_worker/constants/core/string_constants.dart';

import '../../../constants/core/color_constants.dart';
import '../../../constants/core/static_data.dart';

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
                      children: job.tags.map((tag) => _buildTag(tag)).toList(),
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
                        child: _buildIconText(
                          Icons.location_on_outlined,
                          "${job.location} • ${job.distance}",
                        ),
                      ),
                      _buildIconText(Icons.access_time, job.timePosted),
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
                              "Apply Now",
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
                              "View Details"
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

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ColorConstants.textGrey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: ColorConstants.textGrey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    Color bgColor = Colors.grey.shade100;
    Color textColor = ColorConstants.textGrey;
    if (tag == 'Urgent') {
      bgColor = ColorConstants.urgentRed.withOpacity(0.1);
      textColor = ColorConstants.urgentRed;
    } else if (tag == 'New') {
      bgColor = ColorConstants.newBlue.withOpacity(0.1);
      textColor = ColorConstants.newBlue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(
        tag,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}