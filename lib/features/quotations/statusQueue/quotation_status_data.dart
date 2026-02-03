import 'package:flutter/material.dart';
import 'package:voicesewa_client/shared/models/quotation_model.dart';

/// Quotation status configuration data
class QuotationStatusData {
  static Map<QuotationStatus, List<dynamic>> statusInfo = {
    QuotationStatus.submitted: [
      Colors.blue,
      Icons.hourglass_empty,
      'Pending Review',
    ],
    QuotationStatus.accepted: [Colors.green, Icons.check_circle, 'Accepted'],
    QuotationStatus.rejected: [Colors.red, Icons.cancel, 'Rejected'],
    QuotationStatus.withdrawn: [Colors.grey, Icons.remove_circle, 'Withdrawn'],
  };

  static Color getColor(QuotationStatus status) {
    return statusInfo[status]![0] as Color;
  }

  static IconData getIcon(QuotationStatus status) {
    return statusInfo[status]![1] as IconData;
  }

  static String getLabel(QuotationStatus status) {
    return statusInfo[status]![2] as String;
  }
}
