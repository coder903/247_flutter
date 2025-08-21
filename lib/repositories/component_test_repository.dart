// lib/repositories/component_test_repository.dart

import 'base_repository.dart';
import '../models/component_test.dart';

class ComponentTestRepository extends BaseRepository<ComponentTest> {
  static final ComponentTestRepository _instance = ComponentTestRepository._internal();
  factory ComponentTestRepository() => _instance;
  ComponentTestRepository._internal();
  
  @override
  String get tableName => 'component_tests';
  
  @override
  ComponentTest fromMap(Map<String, dynamic> map) => ComponentTest.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(ComponentTest model) => model.toMap();
  
  /// Get component tests by inspection
  Future<List<ComponentTest>> getByInspection(int inspectionId) async {
    return query(
      where: 'inspection_id = ?',
      whereArgs: [inspectionId],
      orderBy: 'created_at ASC',
    );
  }
  
  /// Get component test by device in inspection
  Future<ComponentTest?> getByDeviceAndInspection(int deviceId, int inspectionId) async {
    final results = await query(
      where: 'device_id = ? AND inspection_id = ?',
      whereArgs: [deviceId, inspectionId],
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get failed component tests
  Future<List<ComponentTest>> getFailedTests({int? inspectionId, int? propertyId}) async {
    String where = "test_result = 'Fail'";
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
  
  /// Get component tests with device details
  Future<List<Map<String, dynamic>>> getComponentTestsWithDetails({
    int? inspectionId,
    String? testResult,
    int? deviceTypeId,
  }) async {
    String sql = '''
      SELECT 
        ct.*,
        d.barcode,
        d.location_description,
        d.model_number,
        dt.device_type_name,
        dc.category_name,
        m.manufacturer_name,
        ds.subtype_name
      FROM component_tests ct
      INNER JOIN devices d ON ct.device_id = d.id
      LEFT JOIN device_types dt ON d.device_type_id = dt.id
      LEFT JOIN device_categories dc ON dt.category_id = dc.id
      LEFT JOIN manufacturers m ON d.manufacturer_id = m.id
      LEFT JOIN device_subtypes ds ON d.subtype_id = ds.id
      WHERE ct.deleted = 0 AND d.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (inspectionId != null) {
      sql += ' AND ct.inspection_id = ?';
      args.add(inspectionId);
    }
    
    if (testResult != null) {
      sql += ' AND ct.test_result = ?';
      args.add(testResult);
    }
    
    if (deviceTypeId != null) {
      sql += ' AND d.device_type_id = ?';
      args.add(deviceTypeId);
    }
    
    sql += ' ORDER BY d.location_description ASC';
    
    return rawQuery(sql, args);
  }
  
  /// Get test history for device
  Future<List<Map<String, dynamic>>> getDeviceTestHistory(int deviceId, {int limit = 10}) async {
    const sql = '''
      SELECT 
        ct.*,
        i.inspection_date,
        i.inspection_type,
        i.inspector_name
      FROM component_tests ct
      INNER JOIN inspections i ON ct.inspection_id = i.id
      WHERE ct.device_id = ? 
        AND ct.deleted = 0 
        AND i.deleted = 0
        AND i.is_complete = 1
      ORDER BY i.inspection_date DESC
      LIMIT ?
    ''';
    
    return rawQuery(sql, [deviceId, limit]);
  }
  
  /// Get test statistics by device type
  Future<List<Map<String, dynamic>>> getTestStatsByDeviceType({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String sql = '''
      SELECT 
        dt.device_type_name,
        dc.category_name,
        COUNT(*) as total_tests,
        SUM(CASE WHEN ct.test_result = 'Pass' THEN 1 ELSE 0 END) as passed,
        SUM(CASE WHEN ct.test_result = 'Fail' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN ct.test_result = 'Not Tested' OR ct.test_result IS NULL THEN 1 ELSE 0 END) as not_tested
      FROM component_tests ct
      INNER JOIN devices d ON ct.device_id = d.id
      INNER JOIN device_types dt ON d.device_type_id = dt.id
      INNER JOIN device_categories dc ON dt.category_id = dc.id
      INNER JOIN inspections i ON ct.inspection_id = i.id
      WHERE ct.deleted = 0 AND d.deleted = 0 AND i.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (startDate != null) {
      sql += ' AND i.inspection_date >= ?';
      args.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      sql += ' AND i.inspection_date <= ?';
      args.add(endDate.toIso8601String());
    }
    
    sql += ' GROUP BY dt.id ORDER BY dc.category_name, dt.device_type_name';
    
    return rawQuery(sql, args);
  }
  
  /// Quick test device
  Future<ComponentTest> quickTestDevice({
    required int inspectionId,
    required int deviceId,
    required String testResult,
    String? notes,
    // Device-specific fields
    String? sensitivity,
    String? decibelLevel,
    DateTime? servicedDate,
    DateTime? hydroDate,
    String? size,
    bool? check24hrPost,
  }) async {
    final test = ComponentTest(
      inspectionId: inspectionId,
      deviceId: deviceId,
      testResult: testResult,
      notes: notes,
      sensitivity: sensitivity,
      decibelLevel: decibelLevel,
      servicedDate: servicedDate,
      hydroDate: hydroDate,
      size: size,
      check24hrPost: check24hrPost,
    );
    
    return insert(test);
  }
  
  /// Get devices needing service (fire extinguishers)
  Future<List<Map<String, dynamic>>> getDevicesNeedingService() async {
    const sql = '''
      SELECT DISTINCT
        d.*,
        ct.serviced_date,
        ct.hydro_date,
        p.name as property_name,
        b.building_name
      FROM component_tests ct
      INNER JOIN devices d ON ct.device_id = d.id
      INNER JOIN device_types dt ON d.device_type_id = dt.id
      INNER JOIN properties p ON d.property_id = p.id
      LEFT JOIN buildings b ON p.building_id = b.id
      WHERE ct.deleted = 0 
        AND d.deleted = 0
        AND dt.device_type_name = 'Fire Extinguisher'
        AND ct.id IN (
          SELECT MAX(id) FROM component_tests 
          WHERE deleted = 0 
          GROUP BY device_id
        )
        AND (
          ct.serviced_date IS NULL 
          OR julianday('now') - julianday(ct.serviced_date) >= 365
          OR ct.hydro_date IS NULL
          OR julianday('now') - julianday(ct.hydro_date) >= 1825
        )
      ORDER BY p.name, d.location_description
    ''';
    
    return rawQuery(sql);
  }
}