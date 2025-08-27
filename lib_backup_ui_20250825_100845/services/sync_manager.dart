// lib/services/sync_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../models/sync_queue_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline
}

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  SyncManager._init();

  final _db = DatabaseHelper.instance;
  final _api = ApiService.instance;
  final _connectivity = Connectivity();
  
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;
  
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  SyncStatus _currentStatus = SyncStatus.idle;
  
  /// Initialize sync manager and start monitoring
  Future<void> initialize() async {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && !_isSyncing) {
        // Automatically sync when connection is restored
        performSync();
      }
    });
    
    // Start periodic sync (every 5 minutes when online)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      performSync();
    });
    
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateStatus(connectivityResult == ConnectivityResult.none 
        ? SyncStatus.offline 
        : SyncStatus.idle);
  }
  
  /// Perform manual sync
  Future<void> performSync() async {
    if (_isSyncing) return;
    
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _updateStatus(SyncStatus.offline);
      return;
    }
    
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    
    try {
      // Get pending items from sync queue
      final pendingItems = await _getPendingItems();
      
      if (pendingItems.isEmpty) {
        _updateStatus(SyncStatus.success);
        _isSyncing = false;
        return;
      }
      
      int processed = 0;
      int failed = 0;
      
      for (final item in pendingItems) {
        _updateProgress(SyncProgress(
          total: pendingItems.length,
          completed: processed,
          currentItem: '${item.tableName} - ${item.operationType}',
        ));
        
        try {
          await _syncItem(item);
          await _markItemSynced(item.id!);
          processed++;
        } catch (e) {
          await _markItemFailed(item.id!, e.toString());
          failed++;
        }
      }
      
      _updateStatus(failed == 0 ? SyncStatus.success : SyncStatus.error);
      
      // Sync down changes from server
      await _syncDownFromServer();
      
    } catch (e) {
      _updateStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Get pending sync items
  Future<List<SyncQueueItem>> _getPendingItems() async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'sync_status = ? AND sync_attempts < ?',
      whereArgs: ['pending', 5],
      orderBy: 'priority DESC, created_at ASC',
    );
    
    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }
  
  /// Sync individual item
  Future<void> _syncItem(SyncQueueItem item) async {
    final data = json.decode(item.recordData);
    
    switch (item.operationType.toUpperCase()) {
      case 'CREATE':
        await _syncCreate(item.tableName, data);
        break;
      case 'UPDATE':
        await _syncUpdate(item.tableName, item.recordId, data);
        break;
      case 'DELETE':
        await _syncDelete(item.tableName, item.recordId);
        break;
      case 'UPLOAD_PDF':
        await _syncUploadPDF(item.recordId, data as String);
        break;
    }
  }
  
  /// Sync CREATE operation
  Future<void> _syncCreate(String tableName, Map<String, dynamic> data) async {
    // Remove local-only fields
    data.remove('id');
    data.remove('sync_status');
    data.remove('created_at');
    data.remove('updated_at');
    
    // Call appropriate API endpoint based on table
    final response = await _api.post('/api/$tableName', data: data);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      final serverId = response.data['id'];
      final localId = data['local_id'];
      
      // Update local record with server ID
      final db = await _db.database;
      await db.update(
        tableName,
        {'server_id': serverId, 'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [localId],
      );
    }
  }
  
  /// Sync UPDATE operation
  Future<void> _syncUpdate(String tableName, int recordId, Map<String, dynamic> data) async {
    final db = await _db.database;
    
    // Get server ID
    final records = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    
    if (records.isEmpty) return;
    
    final serverId = records.first['server_id'];
    if (serverId == null) {
      // Record hasn't been synced yet, convert to CREATE
      await _syncCreate(tableName, data);
      return;
    }
    
    // Remove local-only fields
    data.remove('id');
    data.remove('sync_status');
    
    await _api.put('/api/$tableName/$serverId', data: data);
  }
  
  /// Sync DELETE operation
  Future<void> _syncDelete(String tableName, int recordId) async {
    final db = await _db.database;
    
    // Get server ID
    final records = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    
    if (records.isEmpty) return;
    
    final serverId = records.first['server_id'];
    if (serverId != null) {
      await _api.delete('/api/$tableName/$serverId');
    }
  }
  
  /// Sync PDF upload
  Future<void> _syncUploadPDF(int inspectionId, String filePath) async {
    final formData = FormData.fromMap({
      'inspection_id': inspectionId,
      'file': await MultipartFile.fromFile(filePath),
    });
    
    await _api.post('/api/inspections/$inspectionId/report', data: formData);
  }
  
  /// Mark sync item as completed
  Future<void> _markItemSynced(int itemId) async {
    final db = await _db.database;
    await db.update(
      'sync_queue',
      {
        'sync_status': 'synced',
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }
  
  /// Mark sync item as failed
  Future<void> _markItemFailed(int itemId, String error) async {
    final db = await _db.database;
    final maps = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      final currentAttempts = maps.first['sync_attempts'] as int? ?? 0;
      await db.update(
        'sync_queue',
        {
          'sync_attempts': currentAttempts + 1,
          'last_sync_attempt': DateTime.now().toIso8601String(),
          'error_message': error,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );
    }
  }
  
  /// Sync down changes from server
  Future<void> _syncDownFromServer() async {
    final db = await _db.database;
    
    // Get last sync timestamp
    final metadata = await db.query('sync_metadata', limit: 1);
    final lastSync = metadata.isNotEmpty 
        ? DateTime.parse(metadata.first['last_sync_timestamp'] as String)
        : DateTime(2020); // Default to old date for first sync
    
    // Fetch updates from server
    final response = await _api.get('/api/sync/updates', queryParameters: {
      'since': lastSync.toIso8601String(),
      'device_id': await _getDeviceId(),
    });
    
    if (response.statusCode == 200) {
      final updates = response.data['updates'] as Map<String, dynamic>;
      
      // Process updates for each table
      for (final entry in updates.entries) {
        final tableName = entry.key;
        final records = entry.value as List;
        
        for (final record in records) {
          await _syncDownRecord(tableName, record);
        }
      }
      
      // Update sync metadata
      if (metadata.isEmpty) {
        await db.insert(
          'sync_metadata',
          {
            'last_sync_timestamp': DateTime.now().toIso8601String(),
            'last_sync_status': 'success',
            'device_id': await _getDeviceId(),
          },
        );
      } else {
        await db.update(
          'sync_metadata',
          {
            'last_sync_timestamp': DateTime.now().toIso8601String(),
            'last_sync_status': 'success',
          },
          where: 'id = ?',
          whereArgs: [metadata.first['id']],
        );
      }
    }
  }
  
  /// Sync down individual record
  Future<void> _syncDownRecord(String tableName, Map<String, dynamic> record) async {
    final db = await _db.database;
    final serverId = record['id'];
    
    // Check if record exists locally
    final existing = await db.query(
      tableName,
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update existing record
      final localId = existing.first['id'];
      record['sync_status'] = 'synced';
      record['server_id'] = serverId;
      record.remove('id');
      
      await db.update(
        tableName,
        record,
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      // Insert new record
      record['server_id'] = serverId;
      record['sync_status'] = 'synced';
      record.remove('id');
      
      await db.insert(tableName, record);
    }
  }
  
  /// Queue local changes for sync
  Future<void> queueLocalChange({
    required String operationType,
    required String tableName,
    required int recordId,
    Map<String, dynamic>? recordData,
    int priority = 5,
  }) async {
    final db = await _db.database;
    
    await db.insert('sync_queue', {
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'record_data': recordData != null ? json.encode(recordData) : null,
      'priority': priority,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Get device ID for sync tracking
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      // Generate new device ID
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }
  
  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }
  
  /// Update sync progress
  void _updateProgress(SyncProgress progress) {
    _syncProgressController.add(progress);
  }
  
  /// Get current sync status
  SyncStatus get currentStatus => _currentStatus;
  
  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
  
  /// Clear sync queue (for testing)
  Future<void> clearSyncQueue() async {
    final db = await _db.database;
    await db.delete('sync_queue');
  }
  
  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final db = await _db.database;
    
    final pending = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE sync_status = ?',
      ['pending']
    )) ?? 0;
    
    final synced = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE sync_status = ?',
      ['synced']
    )) ?? 0;
    
    final failed = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM sync_queue WHERE sync_status = ? AND sync_attempts >= ?',
      ['pending', 5]
    )) ?? 0;
    
    return {
      'pending': pending,
      'synced': synced,
      'failed': failed,
      'total': pending + synced + failed,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _periodicSyncTimer?.cancel();
    _syncStatusController.close();
    _syncProgressController.close();
  }
}

/// Sync progress data
class SyncProgress {
  final int total;
  final int completed;
  final String currentItem;
  
  SyncProgress({
    required this.total,
    required this.completed,
    required this.currentItem,
  });
  
  double get percentage => total > 0 ? completed / total : 0.0;
}