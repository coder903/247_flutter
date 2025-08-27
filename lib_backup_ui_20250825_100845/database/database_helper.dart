import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fire_inspection.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 2,  // Increment this version number
      onCreate: _createDB,
      onUpgrade: _upgradeDatabase,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // Execute schema creation
    await _createTables(db);
    await _insertDefaultData(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns to inspections table
      await db.execute('ALTER TABLE inspections ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE inspections ADD COLUMN overall_result TEXT');
      await db.execute('ALTER TABLE inspections ADD COLUMN status TEXT DEFAULT "In Progress"');
      await db.execute('ALTER TABLE inspections ADD COLUMN battery_count INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE inspections ADD COLUMN battery_passed INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE inspections ADD COLUMN component_count INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE inspections ADD COLUMN component_passed INTEGER DEFAULT 0');
    }
  }

  Future<void> _createTables(Database db) async {
    // Sync metadata
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync_timestamp TEXT,
        sync_in_progress INTEGER DEFAULT 0,
        last_sync_status TEXT,
        device_id TEXT UNIQUE
      )
    ''');

    // Buildings
    await db.execute('''
      CREATE TABLE buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        building_name TEXT NOT NULL,
        building_code TEXT UNIQUE,
        address TEXT,
        address2 TEXT,
        city TEXT,
        state TEXT,
        zip_code TEXT,
        building_type TEXT,
        floors INTEGER,
        units INTEGER,
        latitude REAL,
        longitude REAL,
        access_notes TEXT,
        contact_name TEXT,
        contact_phone TEXT,
        management_company TEXT,
        management_phone TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0
      )
    ''');

    // Customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        company_name TEXT,
        contact_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        phone_secondary TEXT,
        billing_address TEXT,
        billing_city TEXT,
        billing_state TEXT,
        billing_zip TEXT,
        portal_access INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0
      )
    ''');

    // Properties
    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        name TEXT NOT NULL,
        building_id INTEGER,
        customer_id INTEGER,
        specific_location TEXT,
        qr_code TEXT UNIQUE,
        qr_access_key TEXT,
        monitoring_org TEXT,
        monitoring_phone TEXT,
        monitoring_email TEXT,
        account_number TEXT,
        phone_line_1 TEXT,
        phone_line_2 TEXT,
        transmission_means TEXT DEFAULT 'DACT',
        control_unit_manufacturer TEXT,
        control_unit_model TEXT,
        firmware_revision TEXT,
        primary_voltage TEXT DEFAULT '120VAC',
        primary_amps INTEGER DEFAULT 20,
        overcurrent_protection_type TEXT DEFAULT 'Breaker',
        overcurrent_amps INTEGER DEFAULT 20,
        disconnecting_means_location TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (building_id) REFERENCES buildings(id),
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    // Device Categories
    await db.execute('''
      CREATE TABLE device_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_name TEXT NOT NULL UNIQUE
      )
    ''');

    // Device Types
    await db.execute('''
      CREATE TABLE device_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        device_type_name TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES device_categories(id)
      )
    ''');

    // Manufacturers
    await db.execute('''
      CREATE TABLE manufacturers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manufacturer_name TEXT NOT NULL UNIQUE
      )
    ''');

    // Device SubTypes
    await db.execute('''
      CREATE TABLE device_subtypes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtype_name TEXT NOT NULL UNIQUE
      )
    ''');

    // Devices
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        barcode TEXT UNIQUE NOT NULL,
        property_id INTEGER NOT NULL,
        device_type_id INTEGER NOT NULL,
        manufacturer_id INTEGER,
        model_number TEXT,
        serial_number TEXT,
        installation_date TEXT,
        location_description TEXT,
        address_num TEXT,
        panel_address TEXT,
        subtype_id INTEGER,
        replacement_model TEXT,
        needs_replacement INTEGER DEFAULT 0,
        replacement_reason TEXT,
        photo_path TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (property_id) REFERENCES properties(id),
        FOREIGN KEY (device_type_id) REFERENCES device_types(id),
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(id),
        FOREIGN KEY (subtype_id) REFERENCES device_subtypes(id)
      )
    ''');

    // Inspections
    await db.execute('''
      CREATE TABLE inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        property_id INTEGER NOT NULL,
        inspector_name TEXT,
        inspector_user_id INTEGER,
        start_datetime TEXT,
        completion_datetime TEXT,
        inspection_type TEXT,
        inspection_date TEXT,
        defects TEXT,
        is_complete INTEGER DEFAULT 0,
        panel_temperature_f REAL,
        notes TEXT,
        overall_result TEXT,
        status TEXT DEFAULT 'In Progress',
        battery_count INTEGER DEFAULT 0,
        battery_passed INTEGER DEFAULT 0,
        component_count INTEGER DEFAULT 0,
        component_passed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (property_id) REFERENCES properties(id)
      )
    ''');

    // Battery Tests
    await db.execute('''
      CREATE TABLE battery_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        inspection_id INTEGER NOT NULL,
        barcode TEXT,
        position TEXT,
        serial_number TEXT,
        rated_amp_hours REAL NOT NULL,
        voltage_reading REAL,
        current_reading REAL NOT NULL,
        temperature_f REAL,
        min_current_required REAL,
        passed INTEGER,
        panel_connection TEXT,
        notes TEXT,
        photo_path TEXT,
        video_path TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections(id)
      )
    ''');

    // Component Tests
    await db.execute('''
      CREATE TABLE component_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        inspection_id INTEGER NOT NULL,
        device_id INTEGER NOT NULL,
        test_result TEXT,
        sensitivity TEXT,
        decibel_level TEXT,
        serviced_date TEXT,
        hydro_date TEXT,
        size TEXT,
        check_24hr_post INTEGER,
        notes TEXT,
        photo_path TEXT,
        video_path TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now')),
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (inspection_id) REFERENCES inspections(id),
        FOREIGN KEY (device_id) REFERENCES devices(id)
      )
    ''');

    // Service Tickets
    await db.execute('''
      CREATE TABLE service_tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        property_id INTEGER NOT NULL,
        ticket_number TEXT UNIQUE,
        issue_description TEXT,
        troubleshooting_notes TEXT,
        parts_needed TEXT,
        parts_ordered INTEGER DEFAULT 0,
        parts_received INTEGER DEFAULT 0,
        status TEXT DEFAULT 'Open',
        created_at TEXT DEFAULT (datetime('now')),
        completed_at TEXT,
        sync_status TEXT DEFAULT 'pending',
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (property_id) REFERENCES properties(id)
      )
    ''');

    // Sync Queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        record_data TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        sync_attempts INTEGER DEFAULT 0,
        last_sync_attempt TEXT,
        sync_status TEXT DEFAULT 'pending',
        error_message TEXT,
        priority INTEGER DEFAULT 5
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_buildings_sync ON buildings(sync_status)');
    await db.execute('CREATE INDEX idx_devices_barcode ON devices(barcode)');
    await db.execute('CREATE INDEX idx_devices_property ON devices(property_id)');
    await db.execute('CREATE INDEX idx_inspections_property ON inspections(property_id)');
    await db.execute('CREATE INDEX idx_battery_tests_inspection ON battery_tests(inspection_id)');
    await db.execute('CREATE INDEX idx_component_tests_inspection ON component_tests(inspection_id)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(sync_status, priority)');
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default categories
    final categories = [
      'Initiating',
      'Alarm',
      'Indicating',
      'Auxiliary',
      'Control',
      'Supervisory',
      'Monitor',
      'Fire',
      'Lighting',
      'Safety',
      'Protective',
    ];

    for (final category in categories) {
      await db.insert('device_categories', {'category_name': category});
    }

    // Insert common device types
    final deviceTypes = [
      {'category_id': 1, 'device_type_name': 'Smoke Detector'},
      {'category_id': 1, 'device_type_name': 'Heat Detector'},
      {'category_id': 1, 'device_type_name': 'Pull Station'},
      {'category_id': 1, 'device_type_name': 'Water Flow Switch'},
      {'category_id': 3, 'device_type_name': 'Horn/Strobe'},
      {'category_id': 3, 'device_type_name': 'Strobe'},
      {'category_id': 3, 'device_type_name': 'Horn'},
      {'category_id': 8, 'device_type_name': 'Fire Extinguisher'},
      {'category_id': 9, 'device_type_name': 'Exit Sign'},
      {'category_id': 9, 'device_type_name': 'Emergency Light'},
      {'category_id': 9, 'device_type_name': 'Battery'},
    ];

    for (final type in deviceTypes) {
      await db.insert('device_types', type);
    }

    // Insert common manufacturers
    final manufacturers = [
      'System Sensor',
      'Bosch',
      'Notifier',
      'Simplex',
      'Edwards',
      'Honeywell',
      'Amerex',
      'Brooks',
      'Werker',
    ];

    for (final manufacturer in manufacturers) {
      await db.insert('manufacturers', {'manufacturer_name': manufacturer});
    }

    // Insert common subtypes
    final subtypes = [
      'LED',
      'Incandescent',
      'Photoelectric',
      'Ionization',
      'Duct',
      'Dry Chemical',
      'CO2',
      'Water',
      'Foam',
      'Combination',
      'Power Unit',
      'Sealed Lead Acid',
      'Nickel-Cadmium',
    ];

    for (final subtype in subtypes) {
      await db.insert('device_subtypes', {'subtype_name': subtype});
    }
  }

  // Helper methods for CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    // Soft delete
    return await db.update(
      table,
      {'deleted': 1, 'sync_status': 'pending'},
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}