// lib/repositories/battery_test_repository.dart

import 'base_repository.dart';
import '../models/battery_test.dart';
import '../config/constants.dart';

class BatteryTestRepository extends BaseRepository<BatteryTest> {
  static final BatteryTestRepository _instance = BatteryTestRepository._internal();
  factory BatteryTestRepository() => _instance;
  BatteryTestRepository._internal();
  
  @override
  String get tableName => 'battery_tests';
  
  @override
  BatteryTest fromMap(Map<String, dynamic> map) => BatteryTest.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(BatteryTest model) => model.toMap();
  
  /// Override insert to ensure calculations are done
  @override
  Future<BatteryTest> insert(BatteryTest model) async {
    // Ensure battery test is calculated before inserting
    final calculated = model.recalculate();
    return super.insert(calculated);
  }
  
  /// Override update to ensure calculations are done
  @override
  Future<BatteryTest> update(BatteryTest model) async {
    // Ensure battery test is calculated before updating
    final calculated = model.recalculate();
    return super.update(calculated);
  }
  
  /// Get battery tests by inspection
  Future<List<BatteryTest>> getByInspection(int inspectionId) async {
    return query(
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'position ASC, created_at ASC',
    );
  }
  
  /// Get battery test by barcode
  Future<BatteryTest?> getByBarcode(String barcode, {int? inspectionId}) async {
    String where = 'barcode = ?';
    List<dynamic> whereArgs = [barcode];
    
    if (inspectionId != null) {
      where += ' AND inspection_id = ?';
      whereArgs.add(inspectionId);
    }
    
    final results = await query(
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get failed battery tests
  Future<List<BatteryTest>> getFailedTests({int? inspectionId, int? propertyId}) async {
    String where = 'passed = 0';
    List<dynamic> whereArgs = [];
    
    if (inspectionId != null) {
      where += ' AND inspection_id = ?';
      whereArgs.add(inspectionId);
    }
    
    if (propertyId != null) {
      where += ''' AND inspection_id IN (
        SELECT id FROM inspections 
        WHERE property_id = ? AND deleted = 0
      )''';
      whereArgs.add(propertyId);
    }
    
    return query(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }
  
  /// Get battery tests with details
  Future<List<Map<String, dynamic>>> getBatteryTestsWithDetails({
    int? inspectionId,
    int? propertyId,
    bool? failedOnly,
  }) async {
    String sql = '''
      SELECT 
        bt.*,
        i.inspection_date,
        i.inspection_type,
        i.inspector_name,
        p.name as property_name,
        b.building_name
      FROM battery_tests bt
      INNER JOIN inspections i ON bt.inspection_id = i.id
      INNER JOIN properties p ON i.property_id = p.id
      LEFT JOIN buildings b ON p.building_id = b.id
      WHERE bt.deleted = 0 AND i.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (inspectionId != null) {
      sql += ' AND bt.inspection_id = ?';
      args.add(inspectionId);
    }
    
    if (propertyId != null) {
      sql += ' AND i.property_id = ?';
      args.add(propertyId);
    }
    
    if (failedOnly == true) {
      sql += ' AND bt.passed = 0';
    }
    
    sql += ' ORDER BY i.inspection_date DESC, bt.position ASC';
    
    return rawQuery(sql, args);
  }
  
  /// Get battery test history by position/panel
  Future<List<Map<String, dynamic>>> getBatteryHistory({
    required int propertyId,
    String? position,
    String? panelConnection,
    int limit = 10,
  }) async {
    String sql = '''
      SELECT 
        bt.*,
        i.inspection_date,
        i.inspection_type
      FROM battery_tests bt
      INNER JOIN inspections i ON bt.inspection_id = i.id
      WHERE i.property_id = ? 
        AND bt.deleted = 0 
        AND i.deleted = 0
        AND i.is_complete = 1
    ''';
    
    List<dynamic> args = [propertyId];
    
    if (position != null) {
      sql += ' AND bt.position = ?';
      args.add(position);
    }
    
    if (panelConnection != null) {
      sql += ' AND bt.panel_connection = ?';
      args.add(panelConnection);
    }
    
    sql += ' ORDER BY i.inspection_date DESC LIMIT ?';
    args.add(limit);
    
    return rawQuery(sql, args);
  }
  
  /// Get battery failure rate statistics
  Future<Map<String, dynamic>> getBatteryFailureStats({
    int? propertyId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String sql = '''
      SELECT 
        COUNT(*) as total_tests,
        SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) as passed_count,
        SUM(CASE WHEN passed = 0 THEN 1 ELSE 0 END) as failed_count,
        AVG(current_reading / rated_amp_hours * 100) as avg_percentage,
        AVG(temperature_f) as avg_temperature
      FROM battery_tests bt
      INNER JOIN inspections i ON bt.inspection_id = i.id
      WHERE bt.deleted = 0 AND i.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (propertyId != null) {
      sql += ' AND i.property_id = ?';
      args.add(propertyId);
    }
    
    if (startDate != null) {
      sql += ' AND i.inspection_date >= ?';
      args.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      sql += ' AND i.inspection_date <= ?';
      args.add(endDate.toIso8601String());
    }
    
    final results = await rawQuery(sql, args);
    final stats = results.first;
    
    // Calculate failure rate
    final total = stats['total_tests'] as int;
    final failed = stats['failed_count'] as int;
    stats['failure_rate'] = total > 0 ? (failed / total * 100) : 0.0;
    
    return stats;
  }
  
  /// Get batteries by amp hour rating
  Future<List<BatteryTest>> getByAmpHourRating(double rating, {int? inspectionId}) async {
    String where = 'rated_amp_hours = ?';
    List<dynamic> whereArgs = [rating];
    
    if (inspectionId != null) {
      where += ' AND inspection_id = ?';
      whereArgs.add(inspectionId);
    }
    
    return query(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'position ASC',
    );
  }
  
  /// Quick add battery test
  Future<BatteryTest> quickAddBatteryTest({
    required int inspectionId,
    required String position,
    required double ratedAmpHours,
    required double currentReading,
    double? voltageReading,
    double? temperatureF,
    String? barcode,
    String? panelConnection,
  }) async {
    final batteryTest = BatteryTest(
      inspectionId: inspectionId,
      position: position,
      ratedAmpHours: ratedAmpHours,
      currentReading: currentReading,
      voltageReading: voltageReading,
      temperatureF: temperatureF,
      barcode: barcode,
      panelConnection: panelConnection,
    );
    
    return insert(batteryTest);
  }
}