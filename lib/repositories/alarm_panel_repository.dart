// lib/repositories/alarm_panel_repository.dart

import 'dart:math';
import 'base_repository.dart';
import '../models/alarm_panel.dart';
import '../models/building.dart';
import '../models/customer.dart';
import '../models/device.dart';
import '../database/database_helper.dart';

class AlarmPanelRepository extends BaseRepository<AlarmPanel> {
  static final AlarmPanelRepository _instance = AlarmPanelRepository._internal();
  factory AlarmPanelRepository() => _instance;
  AlarmPanelRepository._internal();
  
  @override
  String get tableName => 'alarmPanels';
  
  @override
  AlarmPanel fromMap(Map<String, dynamic> map) => AlarmPanel.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(AlarmPanel model) => model.toMap();
  
  /// Generate unique QR code for alarm panel
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
  
  /// Get alarm panel by QR code
  Future<AlarmPanel?> getByQrCode(String qrCode) async {
    final results = await query(
      where: 'qr_code = ?',
      whereArgs: [qrCode],
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get alarm panels by building
  Future<List<AlarmPanel>> getByBuilding(int buildingId) async {
    return query(
      where: 'building_id = ?',
      whereArgs: [buildingId],
      orderBy: 'name ASC',
    );
  }
  
  /// Get alarm panels by customer
  Future<List<AlarmPanel>> getByCustomer(int customerId) async {
    return query(
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'name ASC',
    );
  }
  
  /// Get alarmPanels with full details (building and customer info)
  Future<List<Map<String, dynamic>>> getPropertiesWithDetails() async {
    print('DEBUG: Fetching alarm panels with details from database');
    
    const sql = '''
      SELECT 
        p.*,
        b.building_name, b.address as building_address, b.city, b.state,
        c.company_name, c.contact_name as customer_name
      FROM alarmPanels p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE p.deleted = 0
      ORDER BY p.name ASC
    ''';
    
    // Check if the alarmPanels table has any data
    final db = await DatabaseHelper.instance.database;
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM alarmPanels');
    print('DEBUG: Total alarm panels in database: ${count.first['count']}');
    
    // Check if buildings and customers tables have data
    final buildingCount = await db.rawQuery('SELECT COUNT(*) as count FROM buildings');
    print('DEBUG: Total buildings in database: ${buildingCount.first['count']}');
    
    final customerCount = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    print('DEBUG: Total customers in database: ${customerCount.first['count']}');
    
    final results = await rawQuery(sql);
    print('DEBUG: Query returned ${results.length} alarm panels with details');
    
    return results;
  }
  
  /// Get alarmPanels needing inspection
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
        CASE 
          WHEN MAX(i.inspection_date) IS NULL THEN NULL
          ELSE CAST(JULIANDAY('now') - JULIANDAY(MAX(i.inspection_date)) AS INTEGER)
        END as days_since_inspection
      FROM alarmPanels p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      LEFT JOIN inspections i ON p.id = i.alarm_panel_id AND i.deleted = 0 AND i.is_complete = 1
      WHERE p.deleted = 0
      GROUP BY p.id
      HAVING MAX(i.inspection_date) IS NULL OR MAX(i.inspection_date) < ?
      ORDER BY days_since_inspection DESC, p.name ASC
    ''';
    
    return rawQuery(sql, [cutoffDate]);
  }
  
  /// Get all devices for a alarm_panel
  Future<List<Device>> getDevices(int alarmPanelId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'devices',
      where: 'alarm_panel_id = ? AND deleted = 0',
      whereArgs: [alarmPanelId],
      orderBy: 'location_description ASC',
    );
    
    return maps.map((map) => Device.fromMap(map)).toList();
  }
  
  /// Get device count for alarm_panel
  Future<int> getDeviceCount(int alarmPanelId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM devices WHERE alarm_panel_id = ? AND deleted = 0',
      [alarmPanelId],
    );
    
    return result.first['count'] as int;
  }
  
  /// Get alarmPanels with device counts
  Future<List<Map<String, dynamic>>> getPropertiesWithDeviceCounts() async {
    const sql = '''
      SELECT 
        p.*,
        COUNT(d.id) as device_count
      FROM alarmPanels p
      LEFT JOIN devices d ON p.id = d.alarm_panel_id AND d.deleted = 0
      WHERE p.deleted = 0
      GROUP BY p.id
      ORDER BY p.name ASC
    ''';
    
    return rawQuery(sql);
  }
  
  /// Search alarmPanels
  Future<List<AlarmPanel>> search(String query) async {
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
  
  /// Get alarm_panel with related data
  Future<Map<String, dynamic>?> getAlarmPanelWithRelatedData(int alarmPanelId) async {
    const sql = '''
      SELECT 
        p.*,
        b.building_name, b.address as building_address, b.city, b.state,
        c.company_name, c.contact_name as customer_name, c.email as customer_email
      FROM alarmPanels p
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE p.id = ? AND p.deleted = 0
    ''';
    
    final results = await rawQuery(sql, [alarmPanelId]);
    return results.isEmpty ? null : results.first;
  }
}