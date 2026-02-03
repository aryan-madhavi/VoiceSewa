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
        return JobStatus.inProgress;
      default:
        return JobStatus.values.firstWhere(
          (e) => e.name == status.toLowerCase(),
          orElse: () => JobStatus.requested,
        );
    }
  }
}

/// Job model based on Firestore schema
/// Core fields from schema:
/// - service_type, description, address, client_uid, created_at, status
/// - finalized_quotation (optional), scheduled_at (optional - set by client)
///
/// Extended fields for UI (denormalized from quotation when finalized):
/// - workerName, workerRating (cached from accepted quotation)
class Job {
  final String id; // job-uuid
  final Services serviceType;
  final String description;
  final Address address;
  final String clientUid;
  final DateTime createdAt;
  final JobStatus status;

  /// When the job should happen - set by CLIENT during creation
  final DateTime? scheduledAt;

  /// Reference to accepted quotation - set ONLY when client accepts a quotation
  final String? finalizedQuotationId;

  // ✅ Denormalized fields from quotation (for UI convenience)
  // These are fetched from the quotation subcollection when needed
  final String? workerName;
  final double? workerRating;
  final String? finalizedQuotationCost; // Cost from accepted quotation

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
    this.workerName,
    this.workerRating,
    this.finalizedQuotationCost,
  });

  /// Convert to Firestore Map - only schema fields
  /// Note: workerName and workerRating are NOT stored in job document
  /// They come from the quotation subcollection
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'service_type': serviceType.name,
      'description': description,
      'address': address.toMap(),
      'client_uid': clientUid,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status.value,
    };

    // ✅ Add scheduled_at if client specified when they want the job
    if (scheduledAt != null) {
      map['scheduled_at'] = Timestamp.fromDate(scheduledAt!);
    }

    // ❌ finalized_quotation should NOT be set during creation
    // It's ONLY set when client accepts a quotation
    // During job creation, this will always be null
    if (finalizedQuotationId != null) {
      map['finalized_quotation'] = finalizedQuotationId;
    }

    return map;
  }

  /// Create from Firestore Map
  factory Job.fromMap(String id, Map<String, dynamic> map) {
    // Handle finalized_quotation which can be DocumentReference or String
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
      scheduledAt: map['scheduled_at'] != null
          ? (map['scheduled_at'] as Timestamp).toDate()
          : null,
      finalizedQuotationId: finalizedQuotId,
      // Worker info not in job document - must be fetched separately
      workerName: null,
      workerRating: null,
      finalizedQuotationCost: null,
    );
  }

  /// Service details from ServicesData
  Color get serviceColor => ServicesData.services[serviceType]![0] as Color;
  IconData get serviceIcon =>
      ServicesData.services[serviceType]![1] as IconData;
  String get serviceName => ServicesData.services[serviceType]![2] as String;

  /// Status checks
  bool get isRequested => status == JobStatus.requested;
  bool get isQuoted => status == JobStatus.quoted;
  bool get isScheduled => status == JobStatus.scheduled;
  bool get isInProgress => status == JobStatus.inProgress;
  bool get isCompleted => status == JobStatus.completed;
  bool get isCancelled => status == JobStatus.cancelled;
  bool get isRescheduled => status == JobStatus.rescheduled;

  /// Can be cancelled (not in_progress or completed)
  bool get canBeCancelled =>
      status == JobStatus.requested ||
      status == JobStatus.quoted ||
      status == JobStatus.scheduled;

  /// Can be rescheduled (only from in_progress)
  bool get canBeRescheduled => status == JobStatus.inProgress;

  /// Has assigned worker (if finalized quotation exists)
  bool get hasWorker => finalizedQuotationId != null;

  /// Status color for UI
  Color get statusColor {
    switch (status) {
      case JobStatus.requested:
        return Colors.blue;
      case JobStatus.quoted:
        return Colors.purple;
      case JobStatus.scheduled:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.amber;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.red;
      case JobStatus.rescheduled:
        return Colors.teal;
    }
  }

  /// Status label for UI
  String get statusLabel {
    switch (status) {
      case JobStatus.requested:
        return 'Requested';
      case JobStatus.quoted:
        return 'Quotations Received';
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
      case JobStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  /// Formatted date
  String get formattedCreatedDate {
    final months = [
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
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String? get formattedScheduledDate {
    if (scheduledAt == null) return null;
    final months = [
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
    return '${scheduledAt!.day} ${months[scheduledAt!.month - 1]} ${scheduledAt!.year}';
  }

  Job copyWith({
    String? id,
    Services? serviceType,
    String? description,
    Address? address,
    String? clientUid,
    DateTime? createdAt,
    JobStatus? status,
    DateTime? scheduledAt,
    String? finalizedQuotationId,
    String? workerName,
    double? workerRating,
    String? finalizedQuotationCost,
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
      workerName: workerName ?? this.workerName,
      workerRating: workerRating ?? this.workerRating,
      finalizedQuotationCost:
          finalizedQuotationCost ?? this.finalizedQuotationCost,
    );
  }

  @override
  String toString() {
    return 'Job(id: $id, service: $serviceName, status: $statusLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Job && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
