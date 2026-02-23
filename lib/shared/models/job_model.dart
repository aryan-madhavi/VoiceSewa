import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voicesewa_worker/shared/data/service_data.dart';
import 'package:voicesewa_worker/shared/models/job_address_model.dart';

// ── Job Status ─────────────────────────────────────────────────────────────

enum JobStatusType {
  requested,
  quoted,
  scheduled,
  inProgress,
  completed,
  cancelled,
  rescheduled;

  String get value => name;

  static JobStatusType fromString(String s) {
    return JobStatusType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => JobStatusType.requested,
    );
  }

  String get statusLabel {
    switch (this) {
      case JobStatusType.requested:
        return 'Requested';
      case JobStatusType.quoted:
        return 'Quoted';
      case JobStatusType.scheduled:
        return 'Scheduled';
      case JobStatusType.inProgress:
        return 'In Progress';
      case JobStatusType.completed:
        return 'Completed';
      case JobStatusType.cancelled:
        return 'Cancelled';
      case JobStatusType.rescheduled:
        return 'Rescheduled';
    }
  }

  Color get statusColor {
    switch (this) {
      case JobStatusType.requested:
        return const Color(0xFFFF9800);
      case JobStatusType.quoted:
        return const Color(0xFF8B5CF6);
      case JobStatusType.scheduled:
        return const Color(0xFF0056D2);
      case JobStatusType.inProgress:
        return const Color(0xFF00BFA5); 
      case JobStatusType.completed:
        return Colors.green;
      case JobStatusType.cancelled:
        return Colors.red;
      case JobStatusType.rescheduled:
        return const Color(0xFFE67E22);
    }
  }
}

// ── Bill Models ────────────────────────────────────────────────────────────

class BillItem {
  final String name;
  final int quantity;
  final double unitPrice;

  const BillItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
    name: map['name'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

class JobBill {
  final List<BillItem> items;
  final double totalAmount;
  final String notes;
  final DateTime? createdAt;

  const JobBill({
    required this.items,
    required this.totalAmount,
    this.notes = '',
    this.createdAt,
  });

  factory JobBill.fromMap(Map<String, dynamic> map) => JobBill(
    items: (map['items'] as List? ?? [])
        .map((e) => BillItem.fromMap(e as Map<String, dynamic>))
        .toList(),
    totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
    notes: map['notes'] as String? ?? '',
    createdAt: (map['created_at'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'items': items.map((e) => e.toMap()).toList(),
    'total_amount': totalAmount,
    'notes': notes,
    'created_at': FieldValue.serverTimestamp(),
  };
}

// ── Worker Feedback Model ──────────────────────────────────────────────────
// Stored as job.worker_feedback in Firestore.

class WorkerFeedback {
  final double rating;
  final String comment;
  final DateTime? createdAt;

  const WorkerFeedback({
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory WorkerFeedback.fromMap(Map<String, dynamic> map) => WorkerFeedback(
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    comment: map['comment'] as String? ?? '',
    createdAt: (map['created_at'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'rating': rating,
    'comment': comment,
    'created_at': FieldValue.serverTimestamp(),
  };
}

// ── Job Model ──────────────────────────────────────────────────────────────

class JobModel {
  final String jobId;
  final Services serviceType;
  final String description;
  final JobAddress address;
  final String clientUid;
  final DateTime? createdAt;
  final JobStatusType status;
  final DateTime? scheduledAt;
  final String? finalizedQuotationId;
  final double? finalizedQuotationAmount;
  final String? workerName;
  final double? workerRating;
  final String? otp;
  final String? clientPhone;
  final JobBill? bill;
  final WorkerFeedback? workerFeedback; // ← NEW

  const JobModel({
    required this.jobId,
    required this.serviceType,
    required this.description,
    required this.address,
    required this.clientUid,
    this.createdAt,
    this.status = JobStatusType.requested,
    this.scheduledAt,
    this.finalizedQuotationId,
    this.finalizedQuotationAmount,
    this.workerName,
    this.workerRating,
    this.otp,
    this.clientPhone,
    this.bill,
    this.workerFeedback,
  });

  factory JobModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    String? finalizedQuotId;
    final fq = map['finalized_quotation'];
    if (fq is DocumentReference) {
      finalizedQuotId = fq.id;
    } else if (fq is String) {
      finalizedQuotId = fq;
    }

    return JobModel(
      jobId: doc.id,
      serviceType: Services.values.firstWhere(
        (e) => e.name == map['service_type'],
        orElse: () => Services.handymanMasonryWork,
      ),
      description: map['description'] as String? ?? '',
      address: map['address'] != null
          ? JobAddress.fromMap(map['address'] as Map<String, dynamic>)
          : const JobAddress(),
      clientUid: map['client_uid'] as String? ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      status: JobStatusType.fromString(map['status'] as String? ?? 'requested'),
      scheduledAt: (map['scheduled_at'] as Timestamp?)?.toDate(),
      finalizedQuotationId: finalizedQuotId,
      finalizedQuotationAmount: (map['finalized_quotation_amount'] as num?)
          ?.toDouble(),
      workerName: map['worker_name'] as String?,
      workerRating: (map['worker_rating'] as num?)?.toDouble(),
      otp: map['otp'] as String?,
      clientPhone: map['client_phone'] as String?,
      bill: map['bill'] != null
          ? JobBill.fromMap(map['bill'] as Map<String, dynamic>)
          : null,
      workerFeedback: map['worker_feedback'] != null
          ? WorkerFeedback.fromMap(
              map['worker_feedback'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'service_type': serviceType.name,
      'description': description,
      'address': address.toMap(),
      'client_uid': clientUid,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'status': status.value,
    };
    if (scheduledAt != null)
      map['scheduled_at'] = Timestamp.fromDate(scheduledAt!);
    if (finalizedQuotationId != null)
      map['finalized_quotation'] = finalizedQuotationId;
    if (finalizedQuotationAmount != null)
      map['finalized_quotation_amount'] = finalizedQuotationAmount;
    if (workerName != null) map['worker_name'] = workerName;
    if (workerRating != null) map['worker_rating'] = workerRating;
    if (otp != null) map['otp'] = otp;
    if (clientPhone != null) map['client_phone'] = clientPhone;
    if (bill != null) map['bill'] = bill!.toMap();
    if (workerFeedback != null)
      map['worker_feedback'] = workerFeedback!.toMap();
    return map;
  }

  // ── Service helpers ────────────────────────────────────────────────────────

  Color get serviceColor => ServicesData.services[serviceType]![0] as Color;
  IconData get serviceIcon =>
      ServicesData.services[serviceType]![1] as IconData;
  String get serviceName => ServicesData.services[serviceType]![2] as String;

  // ── Status helpers ─────────────────────────────────────────────────────────

  bool get isRequested => status == JobStatusType.requested;
  bool get isQuoted => status == JobStatusType.quoted;
  bool get isScheduled => status == JobStatusType.scheduled;
  bool get isInProgress => status == JobStatusType.inProgress;
  bool get isCompleted => status == JobStatusType.completed;
  bool get isCancelled => status == JobStatusType.cancelled;
  bool get isRescheduled => status == JobStatusType.rescheduled;
  bool get hasWorker => finalizedQuotationId != null;
  bool get hasFeedback => workerFeedback != null; // ← NEW

  String get statusLabel => status.statusLabel;
  Color get statusColor => status.statusColor;

  bool get isScheduledToday {
    if (scheduledAt == null) return false;
    final now = DateTime.now();
    return scheduledAt!.year == now.year &&
        scheduledAt!.month == now.month &&
        scheduledAt!.day == now.day;
  }

  // ── Date helpers ───────────────────────────────────────────────────────────

  String get formattedCreatedDate => createdAt == null ? '' : _fmt(createdAt!);
  String? get formattedScheduledDate =>
      scheduledAt == null ? null : _fmt(scheduledAt!);

  static String _fmt(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  JobModel copyWith({
    String? jobId,
    Services? serviceType,
    String? description,
    JobAddress? address,
    String? clientUid,
    DateTime? createdAt,
    JobStatusType? status,
    DateTime? scheduledAt,
    String? finalizedQuotationId,
    double? finalizedQuotationAmount,
    String? workerName,
    double? workerRating,
    String? otp,
    String? clientPhone,
    JobBill? bill,
    WorkerFeedback? workerFeedback,
  }) {
    return JobModel(
      jobId: jobId ?? this.jobId,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      address: address ?? this.address,
      clientUid: clientUid ?? this.clientUid,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      finalizedQuotationId: finalizedQuotationId ?? this.finalizedQuotationId,
      finalizedQuotationAmount:
          finalizedQuotationAmount ?? this.finalizedQuotationAmount,
      workerName: workerName ?? this.workerName,
      workerRating: workerRating ?? this.workerRating,
      otp: otp ?? this.otp,
      clientPhone: clientPhone ?? this.clientPhone,
      bill: bill ?? this.bill,
      workerFeedback: workerFeedback ?? this.workerFeedback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JobModel && other.jobId == jobId);

  @override
  int get hashCode => jobId.hashCode;

  @override
  String toString() =>
      'JobModel(id: $jobId, service: $serviceName, status: $statusLabel)';
}
