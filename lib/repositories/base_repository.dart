// lib/repositories/base_repository.dart
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../services/sync_manager.dart';
import '../models/base_model.dart';

abstract class BaseRepository<T extends BaseModel> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  
  String get tableName;
  T fromMap(Map<String, dynamic> map);
  
  /// Insert new record
  Future<T> insert(T model) async {
    final db = await _dbHelper.database;
    
    // Insert into database
    final id = await db.insert(
      tableName,
      model.toMap()..['sync_status'] = 'pending',
    );
    
    // Create model with ID
    final newModel = fromMap({
      ...model.toMap(),
      'id': id,
      'sync_status': 'pending',
    });
    
    // Queue for sync
    await _syncManager.queueLocalChange(
      operationType: 'CREATE',
      tableName: tableName,
      recordId: id,
      recordData: {...newModel.toMap(), 'local_id': id},
      priority: _getPriority(tableName),
    );
    
    return newModel;
  }
  
  /// Update existing record
  Future<T> update(T model) async {
    if (model.id == null) {
      throw ArgumentError('Cannot update model without ID');
    }
    
    final db = await _dbHelper.database;
    
    // Update in database
    await db.update(
      tableName,
      model.toMap()
        ..['sync_status'] = 'pending'
        ..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
    
    // Queue for sync
    await _syncManager.queueLocalChange(
      operationType: 'UPDATE',
      tableName: tableName,
      recordId: model.id!,
      recordData: model.toMap(),
      priority: _getPriority(tableName),
    );
    
    return model;
  }
  
  /// Soft delete record
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    
    // Soft delete
    await db.update(
      tableName,
      {
        'deleted': 1,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Queue for sync
    await _syncManager.queueLocalChange(
      operationType: 'DELETE',
      tableName: tableName,
      recordId: id,
      priority: _getPriority(tableName),
    );
  }
  
  /// Get record by ID
  Future<T?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }
  
  /// Get all records
  Future<List<T>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      tableName,
      where: 'deleted = 0',
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Query with conditions
  Future<List<T>> query({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await _dbHelper.database;
    
    // Always exclude deleted records
    final whereClause = where != null 
        ? '($where) AND deleted = 0'
        : 'deleted = 0';
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await _dbHelper.database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// Get sync priority based on table
  int _getPriority(String tableName) {
    // Higher priority for critical data
    switch (tableName) {
      case 'inspections':
      case 'battery_tests':
      case 'component_tests':
        return 10; // Highest priority
      case 'service_tickets':
        return 8;
      case 'devices':
      case 'alarmPanels':
        return 6;
      case 'buildings':
      case 'customers':
        return 4;
      default:
        return 5;
    }
  }
  
  /// Batch insert with sync
  Future<List<T>> batchInsert(List<T> models) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    final results = <T>[];
    
    for (final model in models) {
      batch.insert(
        tableName,
        model.toMap()..['sync_status'] = 'pending',
      );
    }
    
    final ids = await batch.commit();
    
    // Create models with IDs and queue for sync
    for (int i = 0; i < models.length; i++) {
      final id = ids[i] as int;
      final newModel = fromMap({
        ...models[i].toMap(),
        'id': id,
        'sync_status': 'pending',
      });
      
      results.add(newModel);
      
      // Queue for sync
      await _syncManager.queueLocalChange(
        operationType: 'CREATE',
        tableName: tableName,
        recordId: id,
        recordData: {...newModel.toMap(), 'local_id': id},
        priority: _getPriority(tableName),
      );
    }
    
    return results;
  }
  
  /// Get records pending sync
  Future<List<T>> getPendingSync() async {
    return query(
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
  }
  
  /// Mark record as synced
  Future<void> markSynced(int id, {int? serverId}) async {
    final db = await _dbHelper.database;
    final updates = <String, dynamic>{
      'sync_status': 'synced',
    };
    
    if (serverId != null) {
      updates['server_id'] = serverId;
    }
    
    await db.update(
      tableName,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get count of records
  Future<int> getCount({String? where, List<dynamic>? whereArgs}) async {
    final db = await _dbHelper.database;
    
    // Always exclude deleted records
    final whereClause = where != null 
        ? '($where) AND deleted = 0'
        : 'deleted = 0';
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Check if record exists
  Future<bool> exists(int id) async {
    final count = await getCount(
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }
  
  /// Delete multiple records
  Future<void> deleteMultiple(List<int> ids) async {
    if (ids.isEmpty) return;
    
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    for (final id in ids) {
      batch.update(
        tableName,
        {
          'deleted': 1,
          'sync_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
    
    // Queue all deletes for sync
    for (final id in ids) {
      await _syncManager.queueLocalChange(
        operationType: 'DELETE',
        tableName: tableName,
        recordId: id,
        priority: _getPriority(tableName),
      );
    }
  }
  
  /// Update multiple records
  Future<void> updateMultiple(
    Map<String, dynamic> values,
    List<int> ids,
  ) async {
    if (ids.isEmpty) return;
    
    final db = await _dbHelper.database;
    final batch = db.batch();
    
    final updateValues = {
      ...values,
      'sync_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    for (final id in ids) {
      batch.update(
        tableName,
        updateValues,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
    
    // Queue all updates for sync
    for (final id in ids) {
      await _syncManager.queueLocalChange(
        operationType: 'UPDATE',
        tableName: tableName,
        recordId: id,
        recordData: updateValues,
        priority: _getPriority(tableName),
      );
    }
  }
}