// lib/models/sync_queue_item.dart

class SyncQueueItem {
  final int? id;
  final String operationType;
  final String tableName;
  final int recordId;
  final String? recordData;  // Made nullable
  final DateTime createdAt;
  final int syncAttempts;
  final DateTime? lastSyncAttempt;
  final String syncStatus;
  final String? errorMessage;
  final int priority;

  SyncQueueItem({
    this.id,
    required this.operationType,
    required this.tableName,
    required this.recordId,
    this.recordData,  // Now optional
    DateTime? createdAt,  // Optional with default
    this.syncAttempts = 0,
    this.lastSyncAttempt,
    this.syncStatus = 'pending',
    this.errorMessage,
    this.priority = 5,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      operationType: map['operation_type'] as String,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as int,
      recordData: map['record_data'] as String?,  // Nullable
      createdAt: DateTime.parse(map['created_at'] as String),
      syncAttempts: map['sync_attempts'] as int? ?? 0,
      lastSyncAttempt: map['last_sync_attempt'] != null 
          ? DateTime.parse(map['last_sync_attempt'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'pending',
      errorMessage: map['error_message'] as String?,
      priority: map['priority'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      if (recordData != null) 'record_data': recordData,  // Only include if not null
      'created_at': createdAt.toIso8601String(),
      'sync_attempts': syncAttempts,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt!.toIso8601String(),
      'sync_status': syncStatus,
      if (errorMessage != null) 'error_message': errorMessage,
      'priority': priority,
    };
  }

  SyncQueueItem copyWith({
    int? id,
    String? operationType,
    String? tableName,
    int? recordId,
    String? recordData,
    DateTime? createdAt,
    int? syncAttempts,
    DateTime? lastSyncAttempt,
    String? syncStatus,
    String? errorMessage,
    int? priority,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      recordData: recordData ?? this.recordData,
      createdAt: createdAt ?? this.createdAt,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      priority: priority ?? this.priority,
    );
  }

  // Helper methods for retry logic
  bool get hasExceededMaxAttempts => syncAttempts >= 5;
  
  bool get readyForRetry {
    if (lastSyncAttempt == null) return true;
    // Exponential backoff: 1, 2, 4, 8, 16 minutes
    final backoffMinutes = 1 << (syncAttempts - 1);
    final nextRetryTime = lastSyncAttempt!.add(Duration(minutes: backoffMinutes));
    return DateTime.now().isAfter(nextRetryTime);
  }
}