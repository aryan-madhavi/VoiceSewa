import 'package:flutter/material.dart';
import 'package:voicesewa_worker/constants/core/color_constants.dart';
import 'package:voicesewa_worker/constants/core/static_data.dart';

class MyJobCard extends StatelessWidget {
  final Job job;

  const MyJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (job.status){
      case JobStatus.ongoing:
        statusColor = ColorConstants.primaryBlue;
        statusText = "Ongoing";
      case JobStatus.pending:
        statusColor = Colors.orange;
        statusText = "Pending";
      case JobStatus.completed:
        statusColor = Colors.green;
        statusText = "Completed";
      break;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(22, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.textDark,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4,),

                Text(
                  "Client: ${job.clientName}",
                  style: const TextStyle(
                    color: ColorConstants.textGrey,
                    fontSize: 13,
                  ),
                ),

                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                _buildIconText(Icons.location_on_outlined, job.location),

                const SizedBox(height: 8,),

                _buildIconText(Icons.access_time, job.time),

                const SizedBox(height: 8,),

                _buildIconText(Icons.payment_outlined, job.price, isBold: true),

                const SizedBox(height: 20,),

                if (job.status == JobStatus.completed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: (){},
                        child: const Text("View Receipt"),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.call, size: 18,),
                            onPressed: (){},
                            label: const Text("Call"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ColorConstants.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 12,),
                            ),
                          ),
                      ),
                    ],
                  ),

                  if (job.status == JobStatus.ongoing) ...[
                    const SizedBox(height: 12,),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                              "Mark As Completed",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                          ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: statusColor,),
          )
        ],
      ),
    );
  }
}

Widget _buildIconText(IconData icon, String text, {bool isBold = false} ){
  return Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: ColorConstants.textGrey,
      ),
      const SizedBox(width: 8,),
      Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isBold ? ColorConstants.primaryBlue : ColorConstants.textGrey,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ),
    ],
  );
}