// lib/repositories/building_repository.dart

import 'base_repository.dart';
import '../models/building.dart';
import '../models/property.dart';
import '../database/database_helper.dart';

class BuildingRepository extends BaseRepository<Building> {
  static final BuildingRepository _instance = BuildingRepository._internal();
  factory BuildingRepository() => _instance;
  BuildingRepository._internal();
  
  @override
  String get tableName => 'buildings';
  
  @override
  Building fromMap(Map<String, dynamic> map) => Building.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Building model) => model.toMap();
  
  /// Search buildings by name or code
  Future<List<Building>> search(String query) async {
    final searchQuery = '%$query%';
    return super.query(
      where: 'building_name LIKE ? OR building_code LIKE ? OR address LIKE ?',
      whereArgs: [searchQuery, searchQuery, searchQuery],
      orderBy: 'building_name ASC',
    );
  }
  
  /// Get buildings by city and state
  Future<List<Building>> getByLocation(String? city, String? state) async {
    if (city == null && state == null) return getAll();
    
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (city != null) {
      where = 'city = ?';
      whereArgs.add(city);
    }
    
    if (state != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'state = ?';
      whereArgs.add(state);
    }
    
    return query(where: where, whereArgs: whereArgs);
  }
  
  /// Get buildings within radius of coordinates
  Future<List<Building>> getNearby(double latitude, double longitude, double radiusKm) async {
    // Simple distance calculation using Haversine formula approximation
    // For more accuracy, consider using a proper geospatial query
    final buildings = await getAll();
    
    return buildings.where((building) {
      if (building.latitude == null || building.longitude == null) return false;
      
      final latDiff = (building.latitude! - latitude).abs();
      final lonDiff = (building.longitude! - longitude).abs();
      
      // Rough approximation: 1 degree ≈ 111 km
      final approxDistance = ((latDiff * latDiff + lonDiff * lonDiff) * 111 * 111);
      return approxDistance <= (radiusKm * radiusKm);
    }).toList();
  }
  
  /// Get buildings with properties count
  Future<List<Map<String, dynamic>>> getBuildingsWithPropertyCount() async {
    const sql = '''
      SELECT b.*, COUNT(p.id) as property_count
      FROM buildings b
      LEFT JOIN properties p ON b.id = p.building_id AND p.deleted = 0
      WHERE b.deleted = 0
      GROUP BY b.id
      ORDER BY b.building_name ASC
    ''';
    
    return rawQuery(sql);
  }
  
  /// Get all properties for a building
  Future<List<Property>> getProperties(int buildingId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'properties',
      where: 'building_id = ? AND deleted = 0',
      whereArgs: [buildingId],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => Property.fromMap(map)).toList();
  }
  
  /// Check if building code exists
  Future<bool> codeExists(String code, {int? excludeId}) async {
    String where = 'building_code = ?';
    List<dynamic> whereArgs = [code];
    
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final count = await this.getCount(where: where, whereArgs: whereArgs);
    return count > 0;
  }
  
  /// Get buildings with recent inspections
  Future<List<Map<String, dynamic>>> getBuildingsWithRecentInspections({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    
    const sql = '''
      SELECT DISTINCT b.*, MAX(i.inspection_date) as last_inspection_date
      FROM buildings b
      INNER JOIN properties p ON b.id = p.building_id
      INNER JOIN inspections i ON p.id = i.property_id
      WHERE b.deleted = 0 
        AND p.deleted = 0 
        AND i.deleted = 0
        AND i.inspection_date >= ?
      GROUP BY b.id
      ORDER BY last_inspection_date DESC
    ''';
    
    return rawQuery(sql, [cutoffDate]);
  }
}