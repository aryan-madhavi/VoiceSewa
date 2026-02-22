import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors client app's QuotationStatus exactly.
/// Uses .name as the Firestore value.
enum QuotationStatus {
  submitted,
  accepted,
  rejected,
  withdrawn;

  String get value => name;

  static QuotationStatus fromString(String s) {
    return QuotationStatus.values.firstWhere(
      (e) => e.name == s.toLowerCase(),
      orElse: () => QuotationStatus.submitted,
    );
  }
}

/// Mirrors client app's Quotation class strictly.
/// Field names, types, and nullability match schema exactly.
class QuotationModel {
  final String quotationId;
  final String jobId;
  final String workerUid;
  final String workerName;
  final double workerRating; // 'worker_rating'
  final String estimatedCost;
  final String estimatedTime;
  final String description;
  final Map<String, dynamic>? priceBreakdown; // object | null
  final String notes;
  final List<String> portfolioPhotoIds; // array
  final String availability;
  final QuotationStatus status;
  final DateTime? createdAt; // timestamp | null (serverTimestamp on write)
  final DateTime? updatedAt; // timestamp | null
  final bool viewedByClient; // boolean
  final DateTime? viewedAt; // timestamp | null
  final DateTime? acceptedAt; // timestamp | null
  final DateTime? rejectedAt; // timestamp | null
  final DateTime? withdrawnAt; // timestamp | null
  final String? rejectionReason; // string | null
  final String? withdrawalReason; // string | null
  final bool? autoRejected; // boolean | null

  const QuotationModel({
    required this.quotationId,
    required this.jobId,
    required this.workerUid,
    required this.workerName,
    this.workerRating = 0.0,
    required this.estimatedCost,
    required this.estimatedTime,
    required this.description,
    this.priceBreakdown,
    this.notes = '',
    this.portfolioPhotoIds = const [],
    this.availability = '',
    this.status = QuotationStatus.submitted,
    this.createdAt,
    this.updatedAt,
    this.viewedByClient = false,
    this.viewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.withdrawnAt,
    this.rejectionReason,
    this.withdrawalReason,
    this.autoRejected,
  });

  factory QuotationModel.fromDoc(DocumentSnapshot doc, String jobId) {
    final map = doc.data() as Map<String, dynamic>;

    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return QuotationModel(
      quotationId: doc.id,
      jobId: jobId,
      workerUid: map['worker_uid'] as String? ?? '',
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
      createdAt: parseTs(map['created_at']),
      updatedAt: parseTs(map['updated_at']),
      viewedByClient: map['viewed_by_client'] as bool? ?? false,
      viewedAt: parseTs(map['viewed_at']),
      acceptedAt: parseTs(map['accepted_at']),
      rejectedAt: parseTs(map['rejected_at']),
      withdrawnAt: parseTs(map['withdrawn_at']),
      rejectionReason: map['rejection_reason'] as String?,
      withdrawalReason: map['withdrawal_reason'] as String?,
      autoRejected: map['auto_rejected'] as bool?,
    );
  }

  /// toMap — all 14 schema fields, correct types, status always 'submitted' on creation.
  Map<String, dynamic> toMap() => {
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
    'status': 'submitted',
    'created_at': FieldValue.serverTimestamp(),
    'updated_at': null,
    'viewed_by_client': false,
    'viewed_at': null,
    'accepted_at': null,
    'rejected_at': null,
    'withdrawn_at': null,
    'rejection_reason': null,
    'withdrawal_reason': null,
    'auto_rejected': null,
  };

  bool get isPending => status == QuotationStatus.submitted;
  bool get isAccepted => status == QuotationStatus.accepted;
  bool get isRejected => status == QuotationStatus.rejected;
  bool get isWithdrawn => status == QuotationStatus.withdrawn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuotationModel && other.quotationId == quotationId);

  @override
  int get hashCode => quotationId.hashCode;

  @override
  String toString() =>
      'QuotationModel(id: $quotationId, worker: $workerName, cost: $estimatedCost, status: $status)';
}
