import 'base_model.dart';

class SyncQueue {
  final int? id;
  final String operationType; // CREATE, UPDATE, DELETE
  final String tableName;
  final int recordId;
  final String? recordData; // JSON string
  final DateTime createdAt;
  final int syncAttempts;
  final DateTime? lastSyncAttempt;
  final String syncStatus; // pending, syncing, synced, failed
  final String? errorMessage;
  final int priority; // 1-10, lower is higher priority

  SyncQueue({
    this.id,
    required this.operationType,
    required this.tableName,
    required this.recordId,
    this.recordData,
    DateTime? createdAt,
    this.syncAttempts = 0,
    this.lastSyncAttempt,
    this.syncStatus = 'pending',
    this.errorMessage,
    this.priority = 5,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create SyncQueue from SQLite map
  factory SyncQueue.fromMap(Map<String, dynamic> map) {
    return SyncQueue(
      id: map['id'] as int?,
      operationType: map['operation_type'] as String,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as int,
      recordData: map['record_data'] as String?,
      createdAt: BaseModel.parseDateTime(map['created_at'] as String?) ?? DateTime.now(),
      syncAttempts: map['sync_attempts'] as int? ?? 0,
      lastSyncAttempt: BaseModel.parseDateTime(map['last_sync_attempt'] as String?),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      errorMessage: map['error_message'] as String?,
      priority: map['priority'] as int? ?? 5,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'record_data': recordData,
      'created_at': BaseModel.formatDateTime(createdAt),
      'sync_attempts': syncAttempts,
      'last_sync_attempt': BaseModel.formatDateTime(lastSyncAttempt),
      'sync_status': syncStatus,
      'error_message': errorMessage,
      'priority': priority,
    };
  }

  /// Create copy with updated fields
  SyncQueue copyWith({
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
    return SyncQueue(
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

  /// Check if sync has failed too many times
  bool get hasExceededMaxAttempts => syncAttempts >= 5;

  /// Check if ready for retry (after delay)
  bool get readyForRetry {
    if (lastSyncAttempt == null) return true;
    final timeSinceLastAttempt = DateTime.now().difference(lastSyncAttempt!);
    // Exponential backoff: 1 min, 2 min, 4 min, 8 min, 16 min
    final delayMinutes = 1 << (syncAttempts - 1).clamp(0, 4);
    return timeSinceLastAttempt.inMinutes >= delayMinutes;
  }

  /// Get display text for operation
  String get operationText {
    switch (operationType.toUpperCase()) {
      case 'CREATE':
        return 'Create';
      case 'UPDATE':
        return 'Update';
      case 'DELETE':
        return 'Delete';
      default:
        return operationType;
    }
  }

  /// Get table display name
  String get tableDisplayName {
    final tableMap = {
      'buildings': 'Building',
      'customers': 'Customer',
      'properties': 'System',
      'devices': 'Device',
      'inspections': 'Inspection',
      'battery_tests': 'Battery Test',
      'component_tests': 'Component Test',
      'service_tickets': 'Service Ticket',
    };
    return tableMap[tableName] ?? tableName;
  }

  @override
  String toString() => 'SyncQueue($operationText $tableDisplayName #$recordId)';
}

/// Sync metadata for tracking sync state
class SyncMetadata {
  final int? id;
  final DateTime? lastSyncTimestamp;
  final bool syncInProgress;
  final String? lastSyncStatus;
  final String? deviceId;

  SyncMetadata({
    this.id,
    this.lastSyncTimestamp,
    this.syncInProgress = false,
    this.lastSyncStatus,
    this.deviceId,
  });

  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      id: map['id'] as int?,
      lastSyncTimestamp: BaseModel.parseDateTime(map['last_sync_timestamp'] as String?),
      syncInProgress: map['sync_in_progress'] == 1,
      lastSyncStatus: map['last_sync_status'] as String?,
      deviceId: map['device_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'last_sync_timestamp': BaseModel.formatDateTime(lastSyncTimestamp),
      'sync_in_progress': syncInProgress ? 1 : 0,
      'last_sync_status': lastSyncStatus,
      'device_id': deviceId,
    };
  }

  SyncMetadata copyWith({
    int? id,
    DateTime? lastSyncTimestamp,
    bool? syncInProgress,
    String? lastSyncStatus,
    String? deviceId,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      syncInProgress: syncInProgress ?? this.syncInProgress,
      lastSyncStatus: lastSyncStatus ?? this.lastSyncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  /// Check if sync is needed (more than 5 minutes since last sync)
  bool get needsSync {
    if (lastSyncTimestamp == null) return true;
    return DateTime.now().difference(lastSyncTimestamp!).inMinutes > 5;
  }

  /// Get display text for last sync
  String get lastSyncDisplay {
    if (lastSyncTimestamp == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSyncTimestamp!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}