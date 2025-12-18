import 'package:flutter/material.dart';
import 'package:voicesewa_worker/features/jobs/presentation/widgets/my_job_card.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/constants/static_data.dart';
import '../../../core/extensions/context_extensions.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  @override
  Widget build(BuildContext context) {

    final activeJobs = myJobsData.where((j) => j.status != JobStatus.completed).toList();
    final completedJobs = myJobsData.where((j) => j.status == JobStatus.completed).toList();

    return Scaffold(
      backgroundColor: ColorConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20,),
            if (activeJobs.isNotEmpty) ...[
              Padding(
                  padding: const EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  context.loc.activeJobs, // "Active Jobs",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textDark,
                  ),
                ),
              ),
              ...activeJobs.map((job) => MyJobCard(job: job)).toList(),
            ],

            const SizedBox(height: 10,),

            if (completedJobs.isNotEmpty) ...[
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                child: Text(
                  context.loc.recentHistory, // "Recent History",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textDark,
                  ),
                ),
              ),
              ...completedJobs.map((job) => MyJobCard(job: job)).toList(),
            ],

          ],
        ),
      ),
    );
  }
}
