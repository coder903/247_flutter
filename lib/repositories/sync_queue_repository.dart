// lib/repositories/sync_queue_repository.dart

import '../database/database_helper.dart';
import '../models/sync_queue.dart';

class SyncQueueRepository {
  static final SyncQueueRepository _instance = SyncQueueRepository._internal();
  factory SyncQueueRepository() => _instance;
  SyncQueueRepository._internal();
  
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  /// Get all pending sync items
  Future<List<SyncQueue>> getPendingItems() async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: "sync_status = 'pending'",
      orderBy: 'priority ASC, created_at ASC',
    );
    
    return maps.map((map) => SyncQueue.fromMap(map)).toList();
  }
  
  /// Get items ready for retry
  Future<List<SyncQueue>> getItemsReadyForRetry() async {
    final pending = await getPendingItems();
    return pending.where((item) => 
      !item.hasExceededMaxAttempts && item.readyForRetry
    ).toList();
  }
  
  /// Mark item as syncing
  Future<void> markSyncing(int id) async {
    final db = await _db.database;
    await db.update(
      'sync_queue',
      {
        'sync_status': 'syncing',
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Mark item as synced
  Future<void> markSynced(int id) async {
    final db = await _db.database;
    await db.update(
      'sync_queue',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Mark item as failed
  Future<void> markFailed(int id, String errorMessage) async {
    final db = await _db.database;
    final item = await getById(id);
    if (item == null) return;
    
    await db.update(
      'sync_queue',
      {
        'sync_status': 'pending',
        'sync_attempts': item.syncAttempts + 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get item by ID
  Future<SyncQueue?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isEmpty ? null : SyncQueue.fromMap(maps.first);
  }
  
  /// Get count of pending items
  Future<int> getPendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE sync_status = 'pending'",
    );
    
    return result.first['count'] as int;
  }
  
  /// Clean up old synced items
  Future<int> cleanupSyncedItems({int daysToKeep = 7}) async {
    final db = await _db.database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();
    
    return await db.delete(
      'sync_queue',
      where: "sync_status = 'synced' AND created_at < ?",
      whereArgs: [cutoffDate],
    );
  }
  
  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final db = await _db.database;
    const sql = '''
      SELECT 
        sync_status,
        COUNT(*) as count
      FROM sync_queue
      GROUP BY sync_status
    ''';
    
    final results = await db.rawQuery(sql);
    final stats = <String, int>{
      'pending': 0,
      'syncing': 0,
      'synced': 0,
      'total': 0,
    };
    
    for (final row in results) {
      final status = row['sync_status'] as String;
      final count = row['count'] as int;
      stats[status] = count;
      stats['total'] = stats['total']! + count;
    }
    
    return stats;
  }
  
  /// Get items by table
  Future<List<SyncQueue>> getItemsByTable(String tableName) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'table_name = ?',
      whereArgs: [tableName],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => SyncQueue.fromMap(map)).toList();
  }
  
  // --- Sync Metadata ---
  
  /// Get sync metadata
  Future<SyncMetadata?> getSyncMetadata() async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_metadata',
      limit: 1,
    );
    
    return maps.isEmpty ? null : SyncMetadata.fromMap(maps.first);
  }
  
  /// Update sync metadata
  Future<void> updateSyncMetadata({
    DateTime? lastSyncTimestamp,
    bool? syncInProgress,
    String? lastSyncStatus,
    String? deviceId,
  }) async {
    final db = await _db.database;
    final metadata = await getSyncMetadata();
    
    if (metadata == null) {
      // Create new metadata
      await db.insert('sync_metadata', {
        'last_sync_timestamp': lastSyncTimestamp?.toIso8601String(),
        'sync_in_progress': syncInProgress == true ? 1 : 0,
        'last_sync_status': lastSyncStatus,
        'device_id': deviceId,
      });
    } else {
      // Update existing
      final updates = <String, dynamic>{};
      if (lastSyncTimestamp != null) {
        updates['last_sync_timestamp'] = lastSyncTimestamp.toIso8601String();
      }
      if (syncInProgress != null) {
        updates['sync_in_progress'] = syncInProgress ? 1 : 0;
      }
      if (lastSyncStatus != null) {
        updates['last_sync_status'] = lastSyncStatus;
      }
      if (deviceId != null) {
        updates['device_id'] = deviceId;
      }
      
      await db.update(
        'sync_metadata',
        updates,
        where: 'id = ?',
        whereArgs: [metadata.id],
      );
    }
  }
  
  /// Set sync in progress
  Future<void> setSyncInProgress(bool inProgress) async {
    await updateSyncMetadata(syncInProgress: inProgress);
  }
  
  /// Update last sync time
  Future<void> updateLastSyncTime(String status) async {
    await updateSyncMetadata(
      lastSyncTimestamp: DateTime.now(),
      lastSyncStatus: status,
      syncInProgress: false,
    );
  }
}