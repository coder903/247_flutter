// lib/repositories/inspection_repository.dart

import 'base_repository.dart';
import '../models/inspection.dart';
import '../models/battery_test.dart';
import '../models/component_test.dart';
import '../database/database_helper.dart';

class InspectionRepository extends BaseRepository<Inspection> {
  static final InspectionRepository _instance = InspectionRepository._internal();
  factory InspectionRepository() => _instance;
  InspectionRepository._internal();
  
  @override
  String get tableName => 'inspections';
  
  @override
  Inspection fromMap(Map<String, dynamic> map) => Inspection.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Inspection model) => model.toMap();
  
  /// Get inspections by property
  Future<List<Inspection>> getByProperty(int propertyId) async {
    return query(
      where: 'alarm_panel_id = ?',
      whereArgs: [propertyId],
      orderBy: 'inspection_date DESC, created_at DESC',
    );
  }
  
  /// Get inspections by type
  Future<List<Inspection>> getByType(String inspectionType) async {
    return query(
      where: 'inspection_type = ?',
      whereArgs: [inspectionType],
      orderBy: 'inspection_date DESC',
    );
  }
  
  /// Get incomplete inspections
  Future<List<Inspection>> getIncomplete() async {
    return query(
      where: 'is_complete = 0',
      orderBy: 'start_datetime DESC',
    );
  }
  
  /// Get inspections with property details
  Future<List<Map<String, dynamic>>> getInspectionsWithDetails({
    String? inspectorName,
    String? inspectionType,
    bool? isComplete,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String sql = '''
      SELECT 
        i.*,
        p.name as property_name,
        p.account_number,
        b.building_name,
        b.address as building_address,
        c.company_name
      FROM inspections i
      LEFT JOIN alarm_panels p ON i.alarm_panel_id = p.id
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE i.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (inspectorName != null) {
      sql += ' AND i.inspector_name = ?';
      args.add(inspectorName);
    }
    
    if (inspectionType != null) {
      sql += ' AND i.inspection_type = ?';
      args.add(inspectionType);
    }
    
    if (isComplete != null) {
      sql += ' AND i.is_complete = ?';
      args.add(isComplete ? 1 : 0);
    }
    
    if (startDate != null) {
      sql += ' AND i.inspection_date >= ?';
      args.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      sql += ' AND i.inspection_date <= ?';
      args.add(endDate.toIso8601String());
    }
    
    sql += ' ORDER BY i.inspection_date DESC';
    
    return rawQuery(sql, args);
  }
  
  /// Get latest inspection for alarm panel
  Future<Inspection?> getLatestForAlarmPanel(int alarmPanelId) async {
    final results = await query(
      where: 'alarm_panel_id = ? AND is_complete = 1',
      whereArgs: [alarmPanelId],
      orderBy: 'inspection_date DESC',
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get inspections by alarm panel
  Future<List<Inspection>> getByAlarmPanel(int alarmPanelId) async {
    return query(
      where: 'alarm_panel_id = ?',
      whereArgs: [alarmPanelId],
      orderBy: 'inspection_date DESC',
    );
  }
  
  /// Start new inspection
  Future<Inspection> startInspection({
    required int alarmPanelId,
    required String inspectorName,
    int? inspectorUserId,
    String? inspectionType,
    double? panelTemperatureF,
  }) async {
    final now = DateTime.now();
    
    final inspection = Inspection(
      alarmPanelId: alarmPanelId,
      inspectorName: inspectorName,
      inspectorUserId: inspectorUserId,
      startDatetime: now,
      inspectionDate: now,
      inspectionType: inspectionType ?? 'Annual',
      panelTemperatureF: panelTemperatureF,
      isComplete: false,
    );
    
    return insert(inspection);
  }
  
  /// Complete inspection
  Future<Inspection> completeInspection(int inspectionId, {String? defects}) async {
    final inspection = await getById(inspectionId);
    if (inspection == null) {
      throw Exception('Inspection not found');
    }
    
    final completed = inspection.copyWith(
      completionDatetime: DateTime.now(),
      isComplete: true,
      defects: defects,
    );
    
    return update(completed);
  }
  
  /// Get battery tests for inspection
  Future<List<BatteryTest>> getBatteryTests(int inspectionId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'battery_tests',
      where: 'inspection_id = ? AND deleted = 0',
      whereArgs: [inspectionId],
      orderBy: 'position ASC',
    );
    
    return maps.map((map) => BatteryTest.fromMap(map)).toList();
  }
  
  /// Get component tests for inspection
  Future<List<ComponentTest>> getComponentTests(int inspectionId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'component_tests',
      where: 'inspection_id = ? AND deleted = 0',
      whereArgs: [inspectionId],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((map) => ComponentTest.fromMap(map)).toList();
  }
  
  /// Get inspection statistics
  Future<Map<String, dynamic>> getInspectionStats(int inspectionId) async {
    const sql = '''
      SELECT 
        (SELECT COUNT(*) FROM battery_tests WHERE inspection_id = ? AND deleted = 0) as battery_count,
        (SELECT COUNT(*) FROM battery_tests WHERE inspection_id = ? AND deleted = 0 AND passed = 1) as battery_passed,
        (SELECT COUNT(*) FROM component_tests WHERE inspection_id = ? AND deleted = 0) as component_count,
        (SELECT COUNT(*) FROM component_tests WHERE inspection_id = ? AND deleted = 0 AND test_result = 'Pass') as component_passed
    ''';
    
    final results = await rawQuery(sql, [inspectionId, inspectionId, inspectionId, inspectionId]);
    return results.first;
  }
  
  /// Get inspections by date range
  Future<List<Inspection>> getByDateRange(DateTime startDate, DateTime endDate) async {
    return query(
      where: 'inspection_date >= ? AND inspection_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'inspection_date DESC',
    );
  }
  
  /// Get inspector statistics
  Future<List<Map<String, dynamic>>> getInspectorStats({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    
    const sql = '''
      SELECT 
        inspector_name,
        COUNT(*) as inspection_count,
        SUM(CASE WHEN is_complete = 1 THEN 1 ELSE 0 END) as completed_count,
        AVG(CASE WHEN is_complete = 1 THEN 
          CAST((JULIANDAY(completion_datetime) - JULIANDAY(start_datetime)) * 24 * 60 AS INTEGER)
          ELSE NULL END) as avg_duration_minutes
      FROM inspections
      WHERE deleted = 0 AND inspection_date >= ?
      GROUP BY inspector_name
      ORDER BY inspection_count DESC
    ''';
    
    return rawQuery(sql, [cutoffDate]);
  }
}