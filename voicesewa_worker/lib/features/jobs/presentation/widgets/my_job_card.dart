import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:voicesewa_worker/features/jobs/presentation/contact_msg_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/helper_function.dart';
import '../../../../core/constants/static_data.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../providers/chat_provider.dart';
import '../chat_detail_page.dart';

class MyJobCard extends StatefulWidget {
  final Job job;

  const MyJobCard({super.key, required this.job});

  @override
  State<MyJobCard> createState() => _MyJobCardState();
}

class _MyJobCardState extends State<MyJobCard> {
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (widget.job.status){
      case JobStatus.ongoing:
        statusColor = ColorConstants.primaryBlue;
        statusText = context.loc.ongoing;  //"Ongoing";
      case JobStatus.pending:
        statusColor = Colors.orange;
        statusText = context.loc.pending;//"Pending";
      case JobStatus.completed:
        statusColor = Colors.green;
        statusText = context.loc.completed; //"Completed";
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
                      widget.job.title,
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
                  "${context.loc.client}: ${widget.job.clientName}",
                  style: const TextStyle(
                    color: ColorConstants.textGrey,
                    fontSize: 13,
                  ),
                ),

                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                myJobBuildIconText(Icons.location_on_outlined, widget.job.location),

                const SizedBox(height: 8,),

                myJobBuildIconText(Icons.access_time, widget.job.time),

                const SizedBox(height: 8,),

                myJobBuildIconText(Icons.payment_outlined, widget.job.price, isBold: true),

                const SizedBox(height: 20,),

                if (widget.job.status == JobStatus.completed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: (){},
                        child: Text(
                          context.loc.viewReceipt, // "View Receipt"
                        ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person, size: 18,),
                          onPressed: () async {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;

                            final myId = currentUser.uid;
                            // TODO: Delete Worker Here and its Ternary Operator once data is dynamic and connected to db
                            final myName = currentUser.displayName ?? 'Worker';
                            final clientId = widget.job.clientId;
                            final clientName = widget.job.clientName;

                            // Get chat provider
                            final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                            try {
                              // Initiate chat and get unique Room ID
                              final roomId = await chatProvider.initiateChatWithClient(
                                myId: myId,
                                myName: myName,
                                clientId: clientId,
                                clientName: clientName,
                              );

                              // Chat Detail Page Navigation
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailPage(
                                      roomId: roomId,
                                      receiverName: clientName,
                                      receiverId: clientId,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Could not start chat: $e")),
                                );
                              }
                            }
                          },
                          label: Text(
                            context.loc.contact,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConstants.textDark,
                            padding: const EdgeInsets.symmetric(vertical: 12,),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.job.status == JobStatus.ongoing) ...[
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
                          child: Text(
                            context.loc.markAsCompleted, // "Mark As Completed",
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
