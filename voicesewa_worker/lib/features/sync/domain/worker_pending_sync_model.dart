enum WorkerSyncStatus { pending, syncing, completed, failed }

class WorkerPendingSync {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final int queuedAt;
  final int retryCount;
  final String? lastError;
  final WorkerSyncStatus syncStatus;

  const WorkerPendingSync({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.queuedAt,
    required this.retryCount,
    required this.syncStatus,
    this.lastError,
  });

  WorkerPendingSync copyWith({
    int? retryCount,
    String? lastError,
    WorkerSyncStatus? syncStatus,
  }) {
    return WorkerPendingSync(
      id: id,
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      queuedAt: queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'payload': payload,
        'queued_at': queuedAt,
        'retry_count': retryCount,
        'last_error': lastError,
        'sync_status': syncStatus.index,
      };

  static WorkerPendingSync fromMap(Map<String, Object?> m) {
    return WorkerPendingSync(
      id: m['id'] as String,
      entityType: m['entity_type'] as String,
      entityId: m['entity_id'] as String,
      action: m['action'] as String,
      payload: m['payload'] as String,
      queuedAt: m['queued_at'] as int,
      retryCount: (m['retry_count'] as int?) ?? 0,
      lastError: m['last_error'] as String?,
      syncStatus: WorkerSyncStatus.values[m['sync_status'] as int],
    );
  }
}