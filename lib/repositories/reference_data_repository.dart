// lib/repositories/reference_data_repository.dart

import '../database/database_helper.dart';
import '../models/device_references.dart';

class ReferenceDataRepository {
  static final ReferenceDataRepository _instance = ReferenceDataRepository._internal();
  factory ReferenceDataRepository() => _instance;
  ReferenceDataRepository._internal();
  
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // --- Device Categories ---
  
  /// Get all device categories
  Future<List<DeviceCategory>> getCategories() async {
    final db = await _db.database;
    final maps = await db.query(
      'device_categories',
      orderBy: 'category_name ASC',
    );
    
    return maps.map((map) => DeviceCategory.fromMap(map)).toList();
  }
  
  /// Get category by ID
  Future<DeviceCategory?> getCategoryById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'device_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isEmpty ? null : DeviceCategory.fromMap(maps.first);
  }
  
  /// Add new category
  Future<DeviceCategory> addCategory(String categoryName) async {
    final db = await _db.database;
    final id = await db.insert(
      'device_categories',
      {'category_name': categoryName},
    );
    
    return DeviceCategory(id: id, categoryName: categoryName);
  }
  
  // --- Device Types ---
  
  /// Get all device types
  Future<List<DeviceType>> getDeviceTypes() async {
    final db = await _db.database;
    final maps = await db.query(
      'device_types',
      orderBy: 'device_type_name ASC',
    );
    
    return maps.map((map) => DeviceType.fromMap(map)).toList();
  }
  
  /// Get device types by category
  Future<List<DeviceType>> getDeviceTypesByCategory(int categoryId) async {
    final db = await _db.database;
    final maps = await db.query(
      'device_types',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'device_type_name ASC',
    );
    
    return maps.map((map) => DeviceType.fromMap(map)).toList();
  }
  
  /// Get device type by ID
  Future<DeviceType?> getDeviceTypeById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'device_types',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isEmpty ? null : DeviceType.fromMap(maps.first);
  }
  
  /// Add new device type
  Future<DeviceType> addDeviceType(int categoryId, String typeName) async {
    final db = await _db.database;
    final id = await db.insert(
      'device_types',
      {
        'category_id': categoryId,
        'device_type_name': typeName,
      },
    );
    
    return DeviceType(
      id: id,
      categoryId: categoryId,
      deviceTypeName: typeName,
    );
  }
  
  /// Get device types with category names
  Future<List<Map<String, dynamic>>> getDeviceTypesWithCategories() async {
    final db = await _db.database;
    const sql = '''
      SELECT 
        dt.id,
        dt.device_type_name,
        dt.category_id,
        dc.category_name
      FROM device_types dt
      INNER JOIN device_categories dc ON dt.category_id = dc.id
      ORDER BY dc.category_name, dt.device_type_name
    ''';
    
    return db.rawQuery(sql);
  }
  
  // --- Manufacturers ---
  
  /// Get all manufacturers
  Future<List<Manufacturer>> getManufacturers() async {
    final db = await _db.database;
    final maps = await db.query(
      'manufacturers',
      orderBy: 'manufacturer_name ASC',
    );
    
    return maps.map((map) => Manufacturer.fromMap(map)).toList();
  }
  
  /// Get manufacturer by ID
  Future<Manufacturer?> getManufacturerById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'manufacturers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isEmpty ? null : Manufacturer.fromMap(maps.first);
  }
  
  /// Add new manufacturer
  Future<Manufacturer> addManufacturer(String manufacturerName) async {
    final db = await _db.database;
    
    // Check if already exists
    final existing = await db.query(
      'manufacturers',
      where: 'manufacturer_name = ?',
      whereArgs: [manufacturerName],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      return Manufacturer.fromMap(existing.first);
    }
    
    final id = await db.insert(
      'manufacturers',
      {'manufacturer_name': manufacturerName},
    );
    
    return Manufacturer(id: id, manufacturerName: manufacturerName);
  }
  
  /// Search manufacturers
  Future<List<Manufacturer>> searchManufacturers(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'manufacturers',
      where: 'manufacturer_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'manufacturer_name ASC',
      limit: 10,
    );
    
    return maps.map((map) => Manufacturer.fromMap(map)).toList();
  }
  
  // --- Device Subtypes ---
  
  /// Get all subtypes
  Future<List<DeviceSubtype>> getSubtypes() async {
    final db = await _db.database;
    final maps = await db.query(
      'device_subtypes',
      orderBy: 'subtype_name ASC',
    );
    
    return maps.map((map) => DeviceSubtype.fromMap(map)).toList();
  }
  
  /// Get subtype by ID
  Future<DeviceSubtype?> getSubtypeById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'device_subtypes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    return maps.isEmpty ? null : DeviceSubtype.fromMap(maps.first);
  }
  
  /// Add new subtype
  Future<DeviceSubtype> addSubtype(String subtypeName) async {
    final db = await _db.database;
    
    // Check if already exists
    final existing = await db.query(
      'device_subtypes',
      where: 'subtype_name = ?',
      whereArgs: [subtypeName],
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      return DeviceSubtype.fromMap(existing.first);
    }
    
    final id = await db.insert(
      'device_subtypes',
      {'subtype_name': subtypeName},
    );
    
    return DeviceSubtype(id: id, subtypeName: subtypeName);
  }
  
  /// Get subtypes for device type
  /// This returns common subtypes based on device type name
  Future<List<DeviceSubtype>> getSubtypesForDeviceType(String deviceTypeName) async {
    // Define common subtypes for each device type
    final Map<String, List<String>> deviceSubtypes = {
      'Emergency Light': ['LED', 'Incandescent', 'Combination', 'Power Unit'],
      'Exit Sign': ['LED', 'Incandescent'],
      'Smoke Detector': ['Photoelectric', 'Ionization', 'Duct'],
      'Fire Extinguisher': ['Dry Chemical', 'CO2', 'Water', 'Foam'],
      'Battery': ['Sealed Lead Acid', 'Nickel-Cadmium'],
    };
    
    final subtypeNames = deviceSubtypes[deviceTypeName] ?? [];
    final db = await _db.database;
    
    if (subtypeNames.isEmpty) {
      return [];
    }
    
    final placeholders = List.filled(subtypeNames.length, '?').join(',');
    final maps = await db.query(
      'device_subtypes',
      where: 'subtype_name IN ($placeholders)',
      whereArgs: subtypeNames,
      orderBy: 'subtype_name ASC',
    );
    
    return maps.map((map) => DeviceSubtype.fromMap(map)).toList();
  }
  
  // --- Combined Queries ---
  
  /// Initialize reference data if needed
  Future<void> ensureReferenceData() async {
    final categories = await getCategories();
    if (categories.isEmpty) {
      // Database was just created, default data should already be there
      // from DatabaseHelper._insertDefaultData()
      return;
    }
  }
  
  /// Get category and type hierarchy
  Future<Map<DeviceCategory, List<DeviceType>>> getCategoryTypeHierarchy() async {
    final categories = await getCategories();
    final Map<DeviceCategory, List<DeviceType>> hierarchy = {};
    
    for (final category in categories) {
      final types = await getDeviceTypesByCategory(category.id);
      hierarchy[category] = types;
    }
    
    return hierarchy;
  }
}