import 'package:flutter/material.dart';
import 'package:voicesewa_client/shared/models/job_model.dart';

/// Job status configuration data
class JobStatusData {
  static Map<JobStatus, List<dynamic>> statusInfo = {
    JobStatus.requested: [
      Colors.blue,
      Icons.send,
      'Requested',
      'Job request submitted',
    ],
    JobStatus.quoted: [
      Colors.purple,
      Icons.receipt_long,
      'Quotations Received',
      'Workers have sent quotations',
    ],
    JobStatus.scheduled: [
      Colors.orange,
      Icons.schedule,
      'Scheduled',
      'Job is scheduled',
    ],
    JobStatus.inProgress: [
      Colors.amber,
      Icons.engineering,
      'In Progress',
      'Worker is on the job',
    ],
    JobStatus.completed: [
      Colors.green,
      Icons.check_circle,
      'Completed',
      'Job completed successfully',
    ],
    JobStatus.cancelled: [
      Colors.red,
      Icons.cancel,
      'Cancelled',
      'Job was cancelled',
    ],
    JobStatus.rescheduled: [
      Colors.teal,
      Icons.update,
      'Rescheduled',
      'Job has been rescheduled',
    ],
  };

  static Color getColor(JobStatus status) {
    return statusInfo[status]![0] as Color;
  }

  static IconData getIcon(JobStatus status) {
    return statusInfo[status]![1] as IconData;
  }

  static String getLabel(JobStatus status) {
    return statusInfo[status]![2] as String;
  }

  static String getDescription(JobStatus status) {
    return statusInfo[status]![3] as String;
  }
}
