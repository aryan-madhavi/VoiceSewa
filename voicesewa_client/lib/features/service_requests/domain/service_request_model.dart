enum ServiceStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest {
  final String serviceRequestId;
  final String clientId;
  final String? workerId;
  final String category;
  final String title;
  final String? description;
  final String? location;
  final int? scheduledAt;
  final int? createdAt;
  final int? updatedAt;  
  final ServiceStatus status;
  
  ServiceRequest({
    required this.serviceRequestId,
    required this.clientId,
    required this.workerId,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  Map<String, Object?> toMap() => {
    'service_request_id': serviceRequestId,
    'client_id': clientId,
    'worker_id': workerId,
    'category': category,
    'title': title,
    'description': description,
    'location': location,
    'scheduled_at': scheduledAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'status': status.index,
  };

  static ServiceRequest fromMap(Map<String, Object?> m) {
    final si = (m['status'] as int?) ?? 0;
    final statusSafe = si >= 0 && si < ServiceStatus.values.length ? si : 0;

    return ServiceRequest(
      serviceRequestId: m['service_request_id'] as String,
      clientId: m['client_id'] as String,
      workerId: m['worker_id'] as String?,
      category: m['category'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      location: m['location'] as String?,
      scheduledAt: m['scheduled_at'] as int?,
      createdAt: m['created_at'] as int?,
      updatedAt: m['updated_at'] as int?,
      status: ServiceStatus.values[statusSafe],
    );
  }
}
