// lib/repositories/device_repository.dart

import 'base_repository.dart';
import '../models/device.dart';
import '../models/device_references.dart';

class DeviceRepository extends BaseRepository<Device> {
  static final DeviceRepository _instance = DeviceRepository._internal();
  factory DeviceRepository() => _instance;
  DeviceRepository._internal();
  
  @override
  String get tableName => 'devices';
  
  @override
  Device fromMap(Map<String, dynamic> map) => Device.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Device model) => model.toMap();
  
  /// Get device by barcode
  Future<Device?> getByBarcode(String barcode) async {
    final results = await query(
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Check if barcode exists
  Future<bool> barcodeExists(String barcode, {int? excludeId}) async {
    String where = 'barcode = ?';
    List<dynamic> whereArgs = [barcode];
    
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }
  
  /// Get devices by property
  Future<List<Device>> getByProperty(int propertyId) async {
    return query(
      where: 'property_id = ?',
      whereArgs: [propertyId],
      orderBy: 'location_description ASC, barcode ASC',
    );
  }
  
  /// Get devices by type
  Future<List<Device>> getByType(int deviceTypeId, {int? propertyId}) async {
    String where = 'device_type_id = ?';
    List<dynamic> whereArgs = [deviceTypeId];
    
    if (propertyId != null) {
      where += ' AND property_id = ?';
      whereArgs.add(propertyId);
    }
    
    return query(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'location_description ASC',
    );
  }
  
  /// Get devices needing replacement
  Future<List<Device>> getDevicesNeedingReplacement({int? propertyId}) async {
    String where = 'needs_replacement = 1';
    List<dynamic> whereArgs = [];
    
    if (propertyId != null) {
      where += ' AND property_id = ?';
      whereArgs.add(propertyId);
    }
    
    return query(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'property_id ASC, location_description ASC',
    );
  }
  
  /// Get devices with full details
  Future<List<Map<String, dynamic>>> getDevicesWithDetails({int? propertyId}) async {
    String sql = '''
      SELECT 
        d.*,
        dt.device_type_name,
        dc.category_name,
        m.manufacturer_name,
        ds.subtype_name,
        p.name as property_name
      FROM devices d
      LEFT JOIN device_types dt ON d.device_type_id = dt.id
      LEFT JOIN device_categories dc ON dt.category_id = dc.id
      LEFT JOIN manufacturers m ON d.manufacturer_id = m.id
      LEFT JOIN device_subtypes ds ON d.subtype_id = ds.id
      LEFT JOIN properties p ON d.property_id = p.id
      WHERE d.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (propertyId != null) {
      sql += ' AND d.property_id = ?';
      args.add(propertyId);
    }
    
    sql += ' ORDER BY d.location_description ASC';
    
    return rawQuery(sql, args);
  }
  
  /// Get devices by category
  Future<List<Map<String, dynamic>>> getByCategory(int categoryId, {int? propertyId}) async {
    String sql = '''
      SELECT 
        d.*,
        dt.device_type_name,
        m.manufacturer_name
      FROM devices d
      INNER JOIN device_types dt ON d.device_type_id = dt.id
      LEFT JOIN manufacturers m ON d.manufacturer_id = m.id
      WHERE d.deleted = 0 AND dt.category_id = ?
    ''';
    
    List<dynamic> args = [categoryId];
    
    if (propertyId != null) {
      sql += ' AND d.property_id = ?';
      args.add(propertyId);
    }
    
    sql += ' ORDER BY d.location_description ASC';
    
    return rawQuery(sql, args);
  }
  
  /// Search devices
  Future<List<Map<String, dynamic>>> search(String query, {int? propertyId}) async {
    final searchQuery = '%$query%';
    
    String sql = '''
      SELECT 
        d.*,
        dt.device_type_name,
        m.manufacturer_name,
        p.name as property_name
      FROM devices d
      LEFT JOIN device_types dt ON d.device_type_id = dt.id
      LEFT JOIN manufacturers m ON d.manufacturer_id = m.id
      LEFT JOIN properties p ON d.property_id = p.id
      WHERE d.deleted = 0 AND (
        d.barcode LIKE ? OR 
        d.model_number LIKE ? OR 
        d.serial_number LIKE ? OR
        d.location_description LIKE ? OR
        dt.device_type_name LIKE ? OR
        m.manufacturer_name LIKE ?
      )
    ''';
    
    List<dynamic> args = [searchQuery, searchQuery, searchQuery, searchQuery, searchQuery, searchQuery];
    
    if (propertyId != null) {
      sql += ' AND d.property_id = ?';
      args.add(propertyId);
    }
    
    sql += ' ORDER BY d.location_description ASC';
    
    return rawQuery(sql, args);
  }
  
  /// Get devices not tested in inspection
  Future<List<Device>> getUntestedDevices(int propertyId, int inspectionId) async {
    const sql = '''
      SELECT d.*
      FROM devices d
      WHERE d.property_id = ? 
        AND d.deleted = 0
        AND d.id NOT IN (
          SELECT device_id 
          FROM component_tests 
          WHERE inspection_id = ? AND deleted = 0
        )
      ORDER BY d.location_description ASC
    ''';
    
    final maps = await rawQuery(sql, [propertyId, inspectionId]);
    return maps.map((map) => Device.fromMap(map)).toList();
  }
  
  /// Get device test history
  Future<List<Map<String, dynamic>>> getTestHistory(int deviceId, {int limit = 10}) async {
    const sql = '''
      SELECT 
        ct.*,
        i.inspection_date,
        i.inspector_name,
        i.inspection_type
      FROM component_tests ct
      INNER JOIN inspections i ON ct.inspection_id = i.id
      WHERE ct.device_id = ? 
        AND ct.deleted = 0 
        AND i.deleted = 0
      ORDER BY i.inspection_date DESC
      LIMIT ?
    ''';
    
    return rawQuery(sql, [deviceId, limit]);
  }
  
  /// Get device statistics by property
  Future<Map<String, dynamic>> getDeviceStats(int propertyId) async {
    const sql = '''
      SELECT 
        COUNT(*) as total_devices,
        SUM(CASE WHEN needs_replacement = 1 THEN 1 ELSE 0 END) as needs_replacement,
        SUM(CASE WHEN photo_path IS NOT NULL THEN 1 ELSE 0 END) as has_photos,
        COUNT(DISTINCT device_type_id) as device_type_count
      FROM devices
      WHERE property_id = ? AND deleted = 0
    ''';
    
    final results = await rawQuery(sql, [propertyId]);
    return results.first;
  }
}