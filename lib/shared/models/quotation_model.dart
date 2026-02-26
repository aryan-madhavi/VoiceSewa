import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== CHAT MESSAGE MODEL ====================

/// A single chat message stored under:
/// jobs/{jobId}/quotations/{quotationId}/messages/{msgId}
class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final bool isWorker;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.isWorker,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderUid: map['sender_uid'] as String? ?? '',
      senderName: map['sender_name'] as String? ?? '',
      text: map['text'] as String? ?? '',
      isWorker: map['is_worker'] as bool? ?? false,
      sentAt: map['sent_at'] != null
          ? (map['sent_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sender_uid': senderUid,
    'sender_name': senderName,
    'text': text,
    'is_worker': isWorker,
    'sent_at': Timestamp.fromDate(sentAt),
  };
}

// ==================== QUOTATION STATUS ====================

/// Quotation status enum
enum QuotationStatus {
  submitted,
  accepted,
  rejected,
  withdrawn;

  String get value => name;

  static QuotationStatus fromString(String status) {
    return QuotationStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => QuotationStatus.submitted,
    );
  }
}

/// Quotation model - Worker's proposal for a job
class Quotation {
  final String id; // Quotation UUID
  final String workerUid;
  final String workerName; // Denormalized for quick access
  final double workerRating; // Denormalized for quick access
  final String estimatedCost;
  final String estimatedTime;
  final String description;
  final Map<String, dynamic>? priceBreakdown;
  final String notes;
  final List<String> portfolioPhotoIds;
  final String availability;
  final QuotationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool viewedByClient;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? withdrawnAt;
  final String? rejectionReason;
  final String? withdrawalReason;
  final bool autoRejected;

  Quotation({
    required this.id,
    required this.workerUid,
    required this.workerName,
    required this.workerRating,
    required this.estimatedCost,
    required this.estimatedTime,
    required this.description,
    this.priceBreakdown,
    required this.notes,
    required this.portfolioPhotoIds,
    required this.availability,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.viewedByClient = false,
    this.viewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.withdrawnAt,
    this.rejectionReason,
    this.withdrawalReason,
    this.autoRejected = false,
  });

  /// Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'worker_uid': workerUid,
      'worker_name': workerName,
      'worker_rating': workerRating,
      'estimated_cost': estimatedCost,
      'estimated_time': estimatedTime,
      'description': description,
      'price_breakdown': priceBreakdown,
      'notes': notes,
      'portfolio_photo_ids': portfolioPhotoIds,
      'availability': availability,
      'status': status.value,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'viewed_by_client': viewedByClient,
      'viewed_at': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
      'accepted_at': acceptedAt != null
          ? Timestamp.fromDate(acceptedAt!)
          : null,
      'rejected_at': rejectedAt != null
          ? Timestamp.fromDate(rejectedAt!)
          : null,
      'withdrawn_at': withdrawnAt != null
          ? Timestamp.fromDate(withdrawnAt!)
          : null,
      'rejection_reason': rejectionReason,
      'withdrawal_reason': withdrawalReason,
      'auto_rejected': autoRejected,
    };
  }

  /// ✅ FIXED: Create from Firestore Map with proper null timestamp handling
  factory Quotation.fromMap(String id, Map<String, dynamic> map) {
    // ✅ Safe timestamp parser that handles null (offline mode)
    DateTime parseTimestamp(dynamic value) {
      if (value == null) {
        // Offline mode: FieldValue.serverTimestamp() returns null
        print('⚠️ created_at is null (offline mode), using DateTime.now()');
        return DateTime.now();
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      // Fallback
      print('⚠️ Unknown timestamp type: ${value.runtimeType}');
      return DateTime.now();
    }

    // ✅ Safe optional timestamp parser
    DateTime? parseOptionalTimestamp(dynamic value) {
      if (value == null) return null;
      return parseTimestamp(value);
    }

    return Quotation(
      id: id,
      workerUid: map['worker_uid'] as String,
      workerName: map['worker_name'] as String? ?? '',
      workerRating: (map['worker_rating'] as num?)?.toDouble() ?? 0.0,
      estimatedCost: map['estimated_cost'] as String? ?? '',
      estimatedTime: map['estimated_time'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priceBreakdown: map['price_breakdown'] as Map<String, dynamic>?,
      notes: map['notes'] as String? ?? '',
      portfolioPhotoIds: List<String>.from(map['portfolio_photo_ids'] ?? []),
      availability: map['availability'] as String? ?? '',
      status: QuotationStatus.fromString(
        map['status'] as String? ?? 'submitted',
      ),
      createdAt: parseTimestamp(map['created_at']), // ✅ Safe parsing
      updatedAt: parseOptionalTimestamp(map['updated_at']), // ✅ Safe parsing
      viewedByClient: map['viewed_by_client'] as bool? ?? false,
      viewedAt: parseOptionalTimestamp(map['viewed_at']),
      acceptedAt: parseOptionalTimestamp(map['accepted_at']),
      rejectedAt: parseOptionalTimestamp(map['rejected_at']),
      withdrawnAt: parseOptionalTimestamp(map['withdrawn_at']),
      rejectionReason: map['rejection_reason'] as String?,
      withdrawalReason: map['withdrawal_reason'] as String?,
      autoRejected: map['auto_rejected'] as bool? ?? false,
    );
  }

  /// Check if quotation is pending
  bool get isPending => status == QuotationStatus.submitted;

  /// Check if quotation is accepted
  bool get isAccepted => status == QuotationStatus.accepted;

  /// Check if quotation is rejected
  bool get isRejected => status == QuotationStatus.rejected;

  /// Check if quotation is withdrawn
  bool get isWithdrawn => status == QuotationStatus.withdrawn;

  /// Check if quotation can be accepted
  bool get canBeAccepted => status == QuotationStatus.submitted;

  /// Check if quotation can be rejected
  bool get canBeRejected => status == QuotationStatus.submitted;

  /// Check if quotation can be withdrawn
  bool get canBeWithdrawn => status == QuotationStatus.submitted;

  Quotation copyWith({
    String? id,
    String? workerUid,
    String? workerName,
    double? workerRating,
    String? estimatedCost,
    String? estimatedTime,
    String? description,
    Map<String, dynamic>? priceBreakdown,
    String? notes,
    List<String>? portfolioPhotoIds,
    String? availability,
    QuotationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? viewedByClient,
    DateTime? viewedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? withdrawnAt,
    String? rejectionReason,
    String? withdrawalReason,
    bool? autoRejected,
  }) {
    return Quotation(
      id: id ?? this.id,
      workerUid: workerUid ?? this.workerUid,
      workerName: workerName ?? this.workerName,
      workerRating: workerRating ?? this.workerRating,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      description: description ?? this.description,
      priceBreakdown: priceBreakdown ?? this.priceBreakdown,
      notes: notes ?? this.notes,
      portfolioPhotoIds: portfolioPhotoIds ?? this.portfolioPhotoIds,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewedByClient: viewedByClient ?? this.viewedByClient,
      viewedAt: viewedAt ?? this.viewedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      autoRejected: autoRejected ?? this.autoRejected,
    );
  }

  @override
  String toString() {
    return 'Quotation(id: $id, workerName: $workerName, cost: $estimatedCost, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Quotation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
