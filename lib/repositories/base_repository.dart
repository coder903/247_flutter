// lib/repositories/base_repository.dart

import 'dart:convert';
import '../database/database_helper.dart';
import '../models/base_model.dart';
import '../models/sync_queue.dart';

/// Base repository class that provides common database operations
abstract class BaseRepository<T extends BaseModel> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  /// Table name for this repository
  String get tableName;
  
  /// Create model instance from map
  T fromMap(Map<String, dynamic> map);
  
  /// Convert model to map
  Map<String, dynamic> toMap(T model);
  
  /// Insert a new record
  Future<T> insert(T model) async {
    final db = await _db.database;
    
    // Insert the record
    final map = toMap(model);
    final id = await db.insert(tableName, map);
    
    // Add to sync queue if not from server
    if (model.serverId == null) {
      await _addToSyncQueue('CREATE', id, map);
    }
    
    // Return model with ID
    map['id'] = id;
    return fromMap(map);
  }
  
  /// Get a single record by ID
  Future<T?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      tableName,
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }
  
  /// Get a single record by server ID
  Future<T?> getByServerId(int serverId) async {
    final db = await _db.database;
    final maps = await db.query(
      tableName,
      where: 'server_id = ? AND deleted = 0',
      whereArgs: [serverId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }
  
  /// Get all records
  Future<List<T>> getAll({String? orderBy}) async {
    final db = await _db.database;
    final maps = await db.query(
      tableName,
      where: 'deleted = 0',
      orderBy: orderBy ?? 'created_at DESC',
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Get records with custom query
  Future<List<T>> query({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _db.database;
    
    // Add deleted check to where clause
    final whereClause = where != null 
        ? 'deleted = 0 AND ($where)'
        : 'deleted = 0';
    
    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }
  
  /// Update a record
  Future<T> update(T model) async {
    if (model.id == null) {
      throw ArgumentError('Cannot update model without ID');
    }
    
    final db = await _db.database;
    final map = toMap(model);
    
    // Update the timestamp
    map['updated_at'] = DateTime.now().toIso8601String();
    
    // If not synced yet, keep as pending, otherwise mark as modified
    if (model.syncStatus == 'synced') {
      map['sync_status'] = 'modified';
    }
    
    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [model.id],
    );
    
    // Add to sync queue
    await _addToSyncQueue('UPDATE', model.id!, map);
    
    return fromMap(map);
  }
  
  /// Soft delete a record
  Future<void> delete(int id) async {
    final db = await _db.database;
    
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
    
    // Add to sync queue
    await _addToSyncQueue('DELETE', id, null);
  }
  
  /// Count records
  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    final db = await _db.database;
    
    final whereClause = where != null 
        ? 'deleted = 0 AND ($where)'
        : 'deleted = 0';
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE $whereClause',
      whereArgs,
    );
    
    return result.first['count'] as int;
  }
  
  /// Get records that need syncing
  Future<List<T>> getPendingSync() async {
    return query(
      where: "sync_status IN ('pending', 'modified')",
      orderBy: 'updated_at ASC',
    );
  }
  
  /// Mark record as synced
  Future<void> markSynced(int id, int serverId) async {
    final db = await _db.database;
    await db.update(
      tableName,
      {
        'server_id': serverId,
        'sync_status': 'synced',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Add operation to sync queue
  Future<void> _addToSyncQueue(String operation, int recordId, Map<String, dynamic>? data) async {
    final db = await _db.database;
    
    // Check if already in queue for this record
    final existing = await db.query(
      'sync_queue',
      where: 'table_name = ? AND record_id = ? AND sync_status = ?',
      whereArgs: [tableName, recordId, 'pending'],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update existing queue entry
      await db.update(
        'sync_queue',
        {
          'operation_type': operation,
          'record_data': data != null ? jsonEncode(data) : null,
          'created_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // Create new queue entry
      final syncQueue = SyncQueue(
        operationType: operation,
        tableName: tableName,
        recordId: recordId,
        recordData: data != null ? jsonEncode(data) : null,
      );
      
      await db.insert('sync_queue', syncQueue.toMap());
    }
  }
  
  /// Execute raw query
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await _db.database;
    return db.rawQuery(sql, arguments);
  }
  
  /// Execute in transaction
  Future<T> transaction<T>(Future<T> Function() action) async {
    final db = await _db.database;
    return db.transaction((_) => action());
  }
}