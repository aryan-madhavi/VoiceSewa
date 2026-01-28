enum ClientSyncStatus { pending, syncing, completed, failed }

class ClientPendingSync {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final int queuedAt;
  final int retryCount;
  final String? lastError;
  final ClientSyncStatus syncStatus;

  const ClientPendingSync({
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

  ClientPendingSync copyWith({
    int? retryCount,
    String? lastError,
    ClientSyncStatus? syncStatus,
  }) {
    return ClientPendingSync(
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

  static ClientPendingSync fromMap(Map<String, Object?> m) {
    return ClientPendingSync(
      id: m['id'] as String,
      entityType: m['entity_type'] as String,
      entityId: m['entity_id'] as String,
      action: m['action'] as String,
      payload: m['payload'] as String,
      queuedAt: m['queued_at'] as int,
      retryCount: (m['retry_count'] as int?) ?? 0,
      lastError: m['last_error'] as String?,
      syncStatus: ClientSyncStatus.values[m['sync_status'] as int],
    );
  }
}