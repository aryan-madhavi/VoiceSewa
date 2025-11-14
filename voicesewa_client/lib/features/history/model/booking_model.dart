import 'package:flutter/material.dart';
import 'package:voicesewa_client/features/home/data/services.dart';

class BookingModel {
  final Services service; // Now typed, not just a String
  final String description;
  final String workerName;
  final double workerRating;
  final DateTime date; // Use DateTime instead of String for flexibility
  final double amount; // Use double for numeric operations
  final String status;
  final double? userRating; // Nullable until user rates
  final String? eta; // Only for active jobs

  BookingModel({
    required this.service,
    required this.description,
    required this.workerName,
    required this.workerRating,
    required this.date,
    required this.amount,
    required this.status,
    this.userRating,
    this.eta,
  });

  /// ✅ Helper: determines if booking is active
  bool get isActive =>
      ['pending', 'scheduled', 'in progress'].contains(status.toLowerCase());

  /// ✅ Helper: determines if booking is completed or cancelled
  bool get isCompleted =>
      ['completed', 'cancelled'].contains(status.toLowerCase());

  /// ✅ Helper: color mapping based on status
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'scheduled':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// ✅ Service details from ServiceData
  Color get serviceColor => ServiceData.services[service]![0] as Color;
  IconData get serviceIcon => ServiceData.services[service]![1] as IconData;
  String get serviceName => ServiceData.services[service]![2] as String;

  /// ✅ Converts to Map for Firebase / local storage
  Map<String, dynamic> toMap() {
    return {
      'service': service.toString(),
      'description': description,
      'workerName': workerName,
      'workerRating': workerRating,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status,
      'userRating': userRating,
      if (eta != null) 'eta': eta,
    };
  }

  /// ✅ Factory: Create from Map (e.g. Firebase doc or JSON)
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      service: Services.values.firstWhere(
        (e) => e.toString() == map['service'],
        orElse: () => Services.handymanMasonryWork,
      ),
      description: map['description'] ?? '',
      workerName: map['workerName'] ?? map['worker'] ?? '',
      workerRating:
          double.tryParse(
            map['workerRating']?.toString() ?? map['rating']?.toString() ?? '0',
          ) ??
          0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      amount:
          double.tryParse(
            map['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0,
      status: map['status'] ?? '',
      userRating: map['userRating'] == '-' || map['userRating'] == null
          ? null
          : double.tryParse(map['userRating'].toString()),
      eta: map['eta'],
    );
  }

  /// ✅ CopyWith for safe mutations
  BookingModel copyWith({
    Services? service,
    String? description,
    String? workerName,
    double? workerRating,
    DateTime? date,
    double? amount,
    String? status,
    double? userRating,
    String? eta,
  }) {
    return BookingModel(
      service: service ?? this.service,
      description: description ?? this.description,
      workerName: workerName ?? this.workerName,
      workerRating: workerRating ?? this.workerRating,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      eta: eta ?? this.eta,
    );
  }

  /// ✅ Date formatting helper (for UI)
  String get formattedDate =>
      "${date.day} ${_monthName(date.month)} ${date.year}";

  /// Private helper for formattedDate
  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
