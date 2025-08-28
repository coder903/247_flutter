// lib/services/sync_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/sync_queue_item.dart';
import '../database/database_helper.dart';

enum SyncStatus { idle, syncing, success, error, offline }

class SyncProgress {
  final int processed;
  final int total;
  final String message;
  final int completed;
  final String currentItem;
  
  double get percentage => total > 0 ? processed / total : 0.0;

  SyncProgress({
    required this.processed,
    required this.total,
    required this.message,
  }) : completed = processed,
       currentItem = message;
}

class SyncStats {
  final int pendingUploads;
  final int totalSynced;
  final int failedSyncs;
  final DateTime? lastSync;
  final DateTime? lastSyncTime;

  SyncStats({
    required this.pendingUploads,
    required this.totalSynced,
    required this.failedSyncs,
    this.lastSync,
    this.lastSyncTime,
  });
}

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  static SyncManager get instance => _instance;
  factory SyncManager() => _instance;
  
  SyncManager._internal();

  Database? _database;
  bool _isSyncing = false;
  Timer? _syncTimer;
  
  // Streams
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _progressController = StreamController<SyncProgress>.broadcast();
  
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;
  Stream<SyncProgress> get syncProgressStream => _progressController.stream;
  
  // Add getter for onSyncProgress to match what sync_screen expects
  Stream<SyncProgress> get onSyncProgress => syncProgressStream;
  
  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;
  
  /// Initialize sync manager
  Future<void> initialize() async {
    print('SyncManager initialized');
    // Get database path
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/fire_inspection.db';
    _database = await openDatabase(path);
    _startPeriodicSync();
  }
  
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncNow();
    });
  }
  
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
  
  void _updateProgress(int processed, int total, String message) {
    _progressController.add(SyncProgress(
      processed: processed,
      total: total,
      message: message,
    ));
  }
  
  /// Get sync statistics
  Future<SyncStats> getSyncStats() async {
    if (_database == null) {
      return SyncStats(
        pendingUploads: 0, 
        totalSynced: 0,
        failedSyncs: 0,
        lastSync: null,
      );
    }
    
    // Count pending items
    final pendingCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE sync_status = ?', ['pending'])
    ) ?? 0;
    
    // Count total synced
    final syncedCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE sync_status = ?', ['synced'])
    ) ?? 0;
    
    // Count failed syncs (items with sync_attempts > 0 and still pending)
    final failedCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE sync_status = ? AND sync_attempts > ?', ['pending', 0])
    ) ?? 0;
    
    // Get last sync time
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getInt('last_sync_timestamp');
    final lastSyncTime = lastSyncTimestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp)
        : null;
    
    return SyncStats(
      pendingUploads: pendingCount,
      totalSynced: syncedCount,
      failedSyncs: failedCount,
      lastSync: lastSyncTime,
      lastSyncTime: lastSyncTime,
    );
  }
  
  /// Add item to sync queue
  Future<void> addToSyncQueue(String tableName, int recordId, 
      Map<String, dynamic> data, String operationType, {int priority = 5}) async {
    if (_database == null) return;
    
    await _database!.insert('sync_queue', {
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'record_data': jsonEncode(data),
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'sync_attempts': 0,
      'priority': priority,
    });
  }
  
  /// Sync all pending items
  Future<void> syncAll() async {
    await syncNow();
  }
  
  /// Sync now (immediate sync)
  Future<void> syncNow() async {
    if (_isSyncing || _database == null) return;
    
    print('DEBUG: Starting sync operation');
    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    
    try {
      // Check connectivity
      if (!await ApiService.instance.hasConnection()) {
        print('DEBUG: No connection available, marking as offline');
        _updateStatus(SyncStatus.offline);
        return;
      }
      
      // First, let's try to pull data from the server
      print('DEBUG: Attempting to pull data from server');
      
      try {
        final db = await DatabaseHelper.instance.database;
        
        // First, create dummy buildings and customers for the systems
        print('DEBUG: Creating dummy buildings and customers');
        
        // Clear existing data
        await db.delete('alarmPanels');
        await db.delete('buildings');
        await db.delete('customers');
        
        // Create dummy buildings and customers
        final dummyBuildings = [
          {'id': 9, 'building_name': 'Mercy Hospital', 'address': '123 Hospital Way', 'city': 'Dallas', 'state': 'TX', 'sync_status': 'synced', 'deleted': 0},
          {'id': 10, 'building_name': 'Oakwood Elementary', 'address': '456 School St', 'city': 'Dallas', 'state': 'TX', 'sync_status': 'synced', 'deleted': 0},
          {'id': 11, 'building_name': 'Sunset Senior Living', 'address': '789 Sunset Blvd', 'city': 'Dallas', 'state': 'TX', 'sync_status': 'synced', 'deleted': 0},
          {'id': 12, 'building_name': 'TechCorp HQ', 'address': '101 Tech Way', 'city': 'Austin', 'state': 'TX', 'sync_status': 'synced', 'deleted': 0},
        ];
        
        final dummyCustomers = [
          {'id': 4, 'company_name': 'Dallas Healthcare', 'contact_name': 'John Smith', 'email': 'john@healthcare.com', 'sync_status': 'synced', 'deleted': 0},
          {'id': 5, 'company_name': 'Dallas ISD', 'contact_name': 'Mary Johnson', 'email': 'mary@disd.edu', 'sync_status': 'synced', 'deleted': 0},
          {'id': 6, 'company_name': 'Sunset Living Group', 'contact_name': 'Bob Williams', 'email': 'bob@sunsetliving.com', 'sync_status': 'synced', 'deleted': 0},
        ];
        
        // Insert buildings
        for (var building in dummyBuildings) {
          try {
            await db.insert('buildings', building);
            print('DEBUG: Inserted building: ${building['building_name']}');
          } catch (e) {
            print('DEBUG: Error inserting building: $e');
          }
        }
        
        // Insert customers
        for (var customer in dummyCustomers) {
          try {
            await db.insert('customers', customer);
            print('DEBUG: Inserted customer: ${customer['company_name']}');
          } catch (e) {
            print('DEBUG: Error inserting customer: $e');
          }
        }
        
        // Fetch systems/alarm panels
        print('DEBUG: Fetching systems from API');
        final systems = await ApiService.instance.getSystems();
        print('DEBUG: Received ${systems.length} systems from API');
        
        // Insert systems into the database
        if (systems.isNotEmpty) {
          print('DEBUG: Inserting systems into database');
          
          // Insert each system
          for (var system in systems) {
            // Convert to the format expected by the database
            final alarmPanelData = {
              'server_id': system['id'],
              'name': system['name'],
              'building_id': system['location_id'],
              'customer_id': system['customer_id'],
              'specific_location': system['specific_location'],
              'qr_code': system['qr_code'],
              'qr_access_key': system['qr_access_key'],
              'monitoring_org': system['monitoring_company'],
              'monitoring_phone': system['monitoring_phone'],
              'account_number': system['monitoring_account'],
              'control_unit_manufacturer': system['panel_manufacturer'],
              'control_unit_model': system['panel_model'],
              'primary_amps': system['amps'],
              'primary_voltage': '${system['voltage']}VAC',
              'created_at': system['created_at'],
              'updated_at': system['updated_at'],
              'sync_status': 'synced',
              'deleted': 0,
            };
            
            try {
              await db.insert('alarmPanels', alarmPanelData);
              print('DEBUG: Inserted alarm panel: ${system['name']}');
            } catch (e) {
              print('DEBUG: Error inserting alarm panel: $e');
            }
          }
          
          // Now check if the data was inserted correctly
          final count = await db.rawQuery('SELECT COUNT(*) as count FROM alarmPanels');
          print('DEBUG: Total alarm panels in database after insert: ${count.first['count']}');
        }
      } catch (e) {
        print('DEBUG: Error during data pull: $e');
      }
      
      // Get pending items
      final pendingItems = await _database!.query(
        'sync_queue',
        where: 'sync_status = ? AND sync_attempts < ?',
        whereArgs: ['pending', 5],
        orderBy: 'priority DESC, created_at ASC',
      );
      
      print('DEBUG: Found ${pendingItems.length} pending items to sync');
      
      if (pendingItems.isEmpty) {
        _updateStatus(SyncStatus.idle);
        return;
      }
      
      int processed = 0;
      int failed = 0;
      
      for (var item in pendingItems) {
        _updateProgress(processed, pendingItems.length, 
            'Syncing ${item['table_name']} ${item['record_id']}');
        
        try {
          await _syncItem(item);
          processed++;
          
          // Mark as synced
          await _database!.update(
            'sync_queue',
            {'sync_status': 'synced'},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        } catch (e) {
          failed++;
          print('DEBUG: Sync error for item ${item['id']}: $e');
          // Increment retry count
          final syncAttempts = (item['sync_attempts'] as int? ?? 0) + 1;
          
          await _database!.update(
            'sync_queue',
            {
              'sync_attempts': syncAttempts,
              'error_message': e.toString(),
              'last_sync_attempt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
      
      // Save last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      _updateStatus(failed == 0 ? SyncStatus.success : SyncStatus.error);
      _updateProgress(pendingItems.length, pendingItems.length, 
          'Sync complete: $processed synced, $failed failed');
      
    } catch (e) {
      print('DEBUG: Sync error: $e');
      _updateStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync individual item
  Future<void> _syncItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'];
    final operationType = item['operation_type'];
    final recordData = item['record_data'] != null ? jsonDecode(item['record_data']) : null;
    
    print('DEBUG: Syncing $operationType for $tableName with data: $recordData');
    
    switch (tableName) {
      case 'inspections':
        if (operationType == 'CREATE') {
          await ApiService.instance.createInspection(recordData);
        }
        break;
      
      case 'battery_tests':
        if (operationType == 'CREATE') {
          await ApiService.instance.createBatteryTest(
              recordData['inspection_id'], recordData);
        }
        break;
      
      case 'component_tests':
        if (operationType == 'CREATE') {
          await ApiService.instance.createComponentTest(
              recordData['inspection_id'], recordData);
        }
        break;
      
      case 'service_tickets':
        if (operationType == 'CREATE') {
          await ApiService.instance.createServiceTicket(recordData);
        }
        break;
      
      default:
        // Generic sync for other tables
        final api = ApiService.instance;
        switch (operationType.toUpperCase()) {
          case 'CREATE':
            await api.post('/$tableName', data: recordData);
            break;
          case 'UPDATE':
            await api.put('/$tableName/${item['record_id']}', data: recordData);
            break;
          case 'DELETE':
            await api.delete('/$tableName/${item['record_id']}');
            break;
        }
    }
  }
  
  /// Retry failed sync items
  Future<void> retryFailedSyncs() async {
    if (_database == null) return;
    
    // Reset failed items to pending (those with sync_attempts > 0)
    await _database!.rawUpdate('''
      UPDATE sync_queue 
      SET sync_status = 'pending'
      WHERE sync_status = 'pending' 
        AND sync_attempts > 0 
        AND sync_attempts < 5
    ''');
    
    // Trigger sync
    await syncNow();
  }
  
  /// Clear sync queue (removes all synced items)
  Future<void> clearSyncQueue() async {
    if (_database == null) return;
    
    // Delete synced items
    await _database!.delete(
      'sync_queue',
      where: 'sync_status = ?',
      whereArgs: ['synced'],
    );
    
    // Also clear very old failed items (over 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    await _database!.delete(
      'sync_queue',
      where: 'sync_status = ? AND created_at < ?',
      whereArgs: ['pending', thirtyDaysAgo.toIso8601String()],
    );
  }
  
  /// Force sync specific entity
  Future<void> forceSyncEntity(String tableName, int recordId) async {
    await syncNow();
  }
  
  /// Check if entity is synced
  Future<bool> isEntitySynced(String tableName, int recordId) async {
    if (_database == null) return false;
    
    final result = await _database!.query(
      'sync_queue',
      where: 'table_name = ? AND record_id = ? AND sync_status = ?',
      whereArgs: [tableName, recordId, 'pending'],
    );
    
    return result.isEmpty;
  }
  
  /// Queue local change for sync
  Future<void> queueLocalChange({
    required String operationType,
    required String tableName,
    required int recordId,
    Map<String, dynamic>? recordData,
    int priority = 5,
  }) async {
    if (_database == null) return;
    
    await _database!.insert('sync_queue', {
      'operation_type': operationType,
      'table_name': tableName,
      'record_id': recordId,
      'record_data': recordData != null ? jsonEncode(recordData) : null,
      'priority': priority,
      'sync_status': 'pending',
      'sync_attempts': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  /// Cleanup
  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
    _progressController.close();
  }
}