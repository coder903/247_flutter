// lib/repositories/property_repository.dart

import 'dart:math';
import 'base_repository.dart';
import '../models/property.dart';
import '../models/building.dart';
import '../models/customer.dart';
import '../models/device.dart';
import '../database/database_helper.dart';

class PropertyRepository extends BaseRepository<Property> {
  static final PropertyRepository _instance = PropertyRepository._internal();
  factory PropertyRepository() => _instance;
  PropertyRepository._internal();
  
  @override
  String get tableName => 'properties';
  
  @override
  Property fromMap(Map<String, dynamic> map) => Property.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Property model) => model.toMap();
  
  /// Generate unique QR code for property
  Future<String> generateUniqueQrCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    
    String qrCode;
    bool exists;
    
    do {
      qrCode = 'FAS-${List.generate(8, (_) => chars[random.nextInt(chars.length)]).join()}';
      exists = await qrCodeExists(qrCode);
    } while (exists);
    
    return qrCode;
  }
  
  /// Check if QR code exists
  Future<bool> qrCodeExists(String qrCode) async {
    final count = await this.getCount(where: 'qr_code = ?', whereArgs: [qrCode]);
    return count > 0;
  }
  
  /// Get property by QR code
  Future<Property?> getByQrCode(String qrCode) async {
    final results = await query(
      where: 'qr_code = ?',
      whereArgs: [qrCode],
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get properties by building
  Future<List<Property>> getByBuilding(int buildingId) async {
    return query(
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'name ASC',
    );
  }
  
  /// Get properties by customer
  Future<List<Property>> getByCustomer(int customerId) async {
    return query(
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'name ASC',
    );
  }
  
  /// Get properties with full details (building and customer info)
  Future<List<Map<String, dynamic>>> getPropertiesWithDetails() async {
    const sql = '''
      SELECT 
        p.*,
        b.building_name, b.address as building_address, b.city, b.state,
        c.company_name, c.contact_name as customer_name
      FROM properties p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE p.deleted = 0
      ORDER BY p.name ASC
    ''';
    
    return rawQuery(sql);
  }
  
  /// Get properties needing inspection
  Future<List<Map<String, dynamic>>> getPropertiesNeedingInspection({
    String inspectionType = 'Annual',
  }) async {
    // Determine days based on inspection type
    int daysSinceLastInspection;
    switch (inspectionType) {
      case 'Annual':
        daysSinceLastInspection = 365;
        break;
      case 'Semi-Annual':
        daysSinceLastInspection = 182;
        break;
      case 'Quarterly':
        daysSinceLastInspection = 91;
        break;
      case 'Monthly':
        daysSinceLastInspection = 30;
        break;
      default:
        daysSinceLastInspection = 365;
    }
    
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysSinceLastInspection))
        .toIso8601String();
    
    const sql = '''
      SELECT 
        p.*,
        b.building_name, b.address as building_address,
        c.company_name,
        MAX(i.inspection_date) as last_inspection_date,
        JULIANDAY('now') - JULIANDAY(MAX(i.inspection_date)) as days_since_inspection
      FROM properties p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      LEFT JOIN inspections i ON p.id = i.property_id AND i.deleted = 0 AND i.is_complete = 1
      WHERE p.deleted = 0
      GROUP BY p.id
      HAVING last_inspection_date IS NULL OR last_inspection_date < ?
      ORDER BY days_since_inspection DESC NULLS FIRST
    ''';
    
    return rawQuery(sql, [cutoffDate]);
  }
  
  /// Get all devices for a property
  Future<List<Device>> getDevices(int propertyId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'devices',
      where: 'property_id = ? AND deleted = 0',
      whereArgs: [propertyId],
      orderBy: 'location_description ASC',
    );
    
    return maps.map((map) => Device.fromMap(map)).toList();
  }
  
  /// Get device count for property
  Future<int> getDeviceCount(int propertyId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM devices WHERE property_id = ? AND deleted = 0',
      [propertyId],
    );
    
    return result.first['count'] as int;
  }
  
  /// Get properties with device counts
  Future<List<Map<String, dynamic>>> getPropertiesWithDeviceCounts() async {
    const sql = '''
      SELECT 
        p.*,
        COUNT(d.id) as device_count
      FROM properties p
      LEFT JOIN devices d ON p.id = d.property_id AND d.deleted = 0
      WHERE p.deleted = 0
      GROUP BY p.id
      ORDER BY p.name ASC
    ''';
    
    return rawQuery(sql);
  }
  
  /// Search properties
  Future<List<Property>> search(String query) async {
    final searchQuery = '%$query%';
    return super.query(
      where: '''
        name LIKE ? OR 
        account_number LIKE ? OR 
        qr_code LIKE ? OR
        control_unit_manufacturer LIKE ? OR
        control_unit_model LIKE ?
      ''',
      whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery, searchQuery],
      orderBy: 'name ASC',
    );
  }
  
  /// Get property with related data
  Future<Map<String, dynamic>?> getPropertyWithRelatedData(int propertyId) async {
    const sql = '''
      SELECT 
        p.*,
        b.building_name, b.address as building_address, b.city, b.state,
        c.company_name, c.contact_name as customer_name, c.email as customer_email
      FROM properties p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE p.id = ? AND p.deleted = 0
    ''';
    
    final results = await rawQuery(sql, [propertyId]);
    return results.isEmpty ? null : results.first;
  }
}