import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voicesewa_client/shared/data/services_data.dart';
import 'package:voicesewa_client/shared/models/address_model.dart';

/// Job status enum matching the flow
enum JobStatus {
  requested,
  quoted,
  scheduled,
  inProgress,
  completed,
  cancelled,
  rescheduled;

  String get value {
    switch (this) {
      case JobStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  static JobStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'inprogress': // ✅ handles camelCase written by worker app
        return JobStatus.inProgress;
      default:
        return JobStatus.values.firstWhere(
          (e) => e.name == status.toLowerCase(),
          orElse: () => JobStatus.requested,
        );
    }
  }
}

// ==================== HELPERS ====================

/// Safe double parser — handles String or num from Firestore
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// ==================== SUB-MODELS ====================

/// Bill item model matching Firestore schema
class BillItem {
  final String name;
  final int quantity;
  final double unitPrice;

  BillItem({required this.name, required this.quantity, required this.unitPrice});

  double get total => quantity * unitPrice;

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: _parseDouble(map['unit_price']) ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

/// Bill model matching Firestore schema
class JobBill {
  final List<BillItem> items;
  final double totalAmount;
  final String notes;
  final DateTime createdAt;

  JobBill({required this.items, required this.totalAmount, required this.notes, required this.createdAt});

  factory JobBill.fromMap(Map<String, dynamic> map) {
    return JobBill(
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => BillItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: _parseDouble(map['total_amount']) ?? 0.0,
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'items': items.map((i) => i.toMap()).toList(),
        'total_amount': totalAmount,
        'notes': notes,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

/// Feedback model — used for both worker_feedback and client_feedback
class JobFeedback {
  final double rating;
  final String comment;
  final DateTime createdAt;

  JobFeedback({required this.rating, required this.comment, required this.createdAt});

  factory JobFeedback.fromMap(Map<String, dynamic> map) {
    return JobFeedback(
      rating: _parseDouble(map['rating']) ?? 0.0,
      comment: map['comment'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'rating': rating,
        'comment': comment,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

// ==================== JOB MODEL ====================

class Job {
  final String id;
  final Services serviceType;
  final String description;
  final Address address;
  final String clientUid;
  final DateTime createdAt;
  final JobStatus status;
  final DateTime? scheduledAt;
  final String? finalizedQuotationId;
  final double? finalizedQuotationAmount;
  final String? workerName;
  final double? workerRating;
  final String? clientPhone;
  final String? otp;
  final JobBill? bill;
  final DateTime? startedAt;
  final JobFeedback? workerFeedback;
  final JobFeedback? clientFeedback;

  Job({
    required this.id,
    required this.serviceType,
    required this.description,
    required this.address,
    required this.clientUid,
    required this.createdAt,
    required this.status,
    this.scheduledAt,
    this.finalizedQuotationId,
    this.finalizedQuotationAmount,
    this.workerName,
    this.workerRating,
    this.clientPhone,
    this.otp,
    this.bill,
    this.startedAt,
    this.workerFeedback,
    this.clientFeedback,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'service_type': serviceType.name,
      'description': description,
      'address': address.toMap(),
      'client_uid': clientUid,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status.value,
    };
    if (scheduledAt != null) map['scheduled_at'] = Timestamp.fromDate(scheduledAt!);
    if (finalizedQuotationId != null) map['finalized_quotation'] = finalizedQuotationId;
    if (finalizedQuotationAmount != null) map['finalized_quotation_amount'] = finalizedQuotationAmount;
    if (workerName != null) map['worker_name'] = workerName;
    if (workerRating != null) map['worker_rating'] = workerRating;
    if (clientPhone != null) map['client_phone'] = clientPhone;
    if (otp != null) map['otp'] = otp;
    if (bill != null) map['bill'] = bill!.toMap();
    if (startedAt != null) map['started_at'] = Timestamp.fromDate(startedAt!);
    if (workerFeedback != null) map['worker_feedback'] = workerFeedback!.toMap();
    if (clientFeedback != null) map['client_feedback'] = clientFeedback!.toMap();
    return map;
  }

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    String? finalizedQuotId;
    final finalizedQuot = map['finalized_quotation'];
    if (finalizedQuot is DocumentReference) {
      finalizedQuotId = finalizedQuot.id;
    } else if (finalizedQuot is String) {
      finalizedQuotId = finalizedQuot;
    }

    return Job(
      id: id,
      serviceType: Services.values.firstWhere(
        (e) => e.name == map['service_type'],
        orElse: () => Services.handymanMasonryWork,
      ),
      description: map['description'] as String? ?? '',
      address: Address.fromMap(map['address'] as Map<String, dynamic>),
      clientUid: map['client_uid'] as String,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      status: JobStatus.fromString(map['status'] as String? ?? 'requested'),
      scheduledAt: map['scheduled_at'] != null ? (map['scheduled_at'] as Timestamp).toDate() : null,
      finalizedQuotationId: finalizedQuotId,
      finalizedQuotationAmount: _parseDouble(map['finalized_quotation_amount']),
      workerName: map['worker_name'] as String?,
      workerRating: _parseDouble(map['worker_rating']),
      clientPhone: map['client_phone'] as String?,
      otp: map['otp'] as String?,
      bill: map['bill'] != null ? JobBill.fromMap(map['bill'] as Map<String, dynamic>) : null,
      startedAt: map['started_at'] != null ? (map['started_at'] as Timestamp).toDate() : null,
      workerFeedback: map['worker_feedback'] != null ? JobFeedback.fromMap(map['worker_feedback'] as Map<String, dynamic>) : null,
      clientFeedback: map['client_feedback'] != null ? JobFeedback.fromMap(map['client_feedback'] as Map<String, dynamic>) : null,
    );
  }

  Color get serviceColor => ServicesData.services[serviceType]![0] as Color;
  IconData get serviceIcon => ServicesData.services[serviceType]![1] as IconData;
  String get serviceName => ServicesData.services[serviceType]![2] as String;

  bool get isRequested => status == JobStatus.requested;
  bool get isQuoted => status == JobStatus.quoted;
  bool get isScheduled => status == JobStatus.scheduled;
  bool get isInProgress => status == JobStatus.inProgress;
  bool get isCompleted => status == JobStatus.completed;
  bool get isCancelled => status == JobStatus.cancelled;
  bool get isRescheduled => status == JobStatus.rescheduled;

  bool get canBeCancelled =>
      status == JobStatus.requested ||
      status == JobStatus.quoted ||
      status == JobStatus.scheduled;

  // ✅ FIXED: Reschedule only allowed when job is scheduled (not inProgress)
  bool get canBeRescheduled => status == JobStatus.scheduled;

  bool get hasWorker => workerName != null && workerName!.isNotEmpty;

  Color get statusColor {
    switch (status) {
      case JobStatus.requested: return Colors.blue;
      case JobStatus.quoted: return Colors.purple;
      case JobStatus.scheduled: return Colors.orange;
      case JobStatus.inProgress: return Colors.amber;
      case JobStatus.completed: return Colors.green;
      case JobStatus.cancelled: return Colors.red;
      case JobStatus.rescheduled: return Colors.teal;
    }
  }

  String get statusLabel {
    switch (status) {
      case JobStatus.requested: return 'Requested';
      case JobStatus.quoted: return 'Quotations Received';
      case JobStatus.scheduled: return 'Scheduled';
      case JobStatus.inProgress: return 'In Progress';
      case JobStatus.completed: return 'Completed';
      case JobStatus.cancelled: return 'Cancelled';
      case JobStatus.rescheduled: return 'Rescheduled';
    }
  }

  String get formattedCreatedDate => _formatDate(createdAt);
  String? get formattedScheduledDate => scheduledAt != null ? _formatDate(scheduledAt!) : null;
  String? get formattedStartedDate => startedAt != null ? _formatDate(startedAt!) : null;

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Job copyWith({
    String? id, Services? serviceType, String? description, Address? address,
    String? clientUid, DateTime? createdAt, JobStatus? status, DateTime? scheduledAt,
    String? finalizedQuotationId, double? finalizedQuotationAmount,
    String? workerName, double? workerRating, String? clientPhone,
    String? otp, JobBill? bill, DateTime? startedAt,
    JobFeedback? workerFeedback, JobFeedback? clientFeedback,
  }) {
    return Job(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      address: address ?? this.address,
      clientUid: clientUid ?? this.clientUid,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      finalizedQuotationId: finalizedQuotationId ?? this.finalizedQuotationId,
      finalizedQuotationAmount: finalizedQuotationAmount ?? this.finalizedQuotationAmount,
      workerName: workerName ?? this.workerName,
      workerRating: workerRating ?? this.workerRating,
      clientPhone: clientPhone ?? this.clientPhone,
      otp: otp ?? this.otp,
      bill: bill ?? this.bill,
      startedAt: startedAt ?? this.startedAt,
      workerFeedback: workerFeedback ?? this.workerFeedback,
      clientFeedback: clientFeedback ?? this.clientFeedback,
    );
  }

  @override
  String toString() => 'Job(id: $id, service: $serviceName, status: $statusLabel)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}