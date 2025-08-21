// lib/repositories/customer_repository.dart

import 'base_repository.dart';
import '../models/customer.dart';
import '../models/property.dart';
import '../database/database_helper.dart';

class CustomerRepository extends BaseRepository<Customer> {
  static final CustomerRepository _instance = CustomerRepository._internal();
  factory CustomerRepository() => _instance;
  CustomerRepository._internal();
  
  @override
  String get tableName => 'customers';
  
  @override
  Customer fromMap(Map<String, dynamic> map) => Customer.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Customer model) => model.toMap();
  
  /// Search customers by name, email, or phone
  Future<List<Customer>> search(String query) async {
    final searchQuery = '%$query%';
    return super.query(
      where: '''
        company_name LIKE ? OR 
        contact_name LIKE ? OR 
        email LIKE ? OR 
        phone LIKE ? OR 
        phone_secondary LIKE ?
      ''',
      whereArgs: [searchQuery, searchQuery, searchQuery, searchQuery, searchQuery],
      orderBy: 'COALESCE(company_name, contact_name) ASC',
    );
  }
  
  /// Get customer by email
  Future<Customer?> getByEmail(String email) async {
    final results = await query(
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    
    return results.isEmpty ? null : results.first;
  }
  
  /// Get customers with portal access
  Future<List<Customer>> getPortalUsers() async {
    return query(
      where: 'portal_access = 1',
      orderBy: 'COALESCE(company_name, contact_name) ASC',
    );
  }
  
  /// Get all properties for a customer
  Future<List<Property>> getProperties(int customerId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'properties',
      where: 'customer_id = ? AND deleted = 0',
      whereArgs: [customerId],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => Property.fromMap(map)).toList();
  }
  
  /// Get customers with properties count
  Future<List<Map<String, dynamic>>> getCustomersWithPropertyCount() async {
    const sql = '''
      SELECT c.*, COUNT(p.id) as property_count
      FROM customers c
      LEFT JOIN properties p ON c.id = p.customer_id AND p.deleted = 0
      WHERE c.deleted = 0
      GROUP BY c.id
      ORDER BY COALESCE(c.company_name, c.contact_name) ASC
    ''';
    
    return rawQuery(sql);
  }
  
  /// Get customers with recent activity
  Future<List<Map<String, dynamic>>> getCustomersWithRecentActivity({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    
    const sql = '''
      SELECT DISTINCT c.*, MAX(i.inspection_date) as last_activity_date
      FROM customers c
      INNER JOIN properties p ON c.id = p.customer_id
      LEFT JOIN inspections i ON p.id = i.property_id AND i.deleted = 0
      WHERE c.deleted = 0 
        AND p.deleted = 0
        AND (i.inspection_date >= ? OR i.inspection_date IS NULL)
      GROUP BY c.id
      ORDER BY last_activity_date DESC NULLS LAST
    ''';
    
    return rawQuery(sql, [cutoffDate]);
  }
  
  /// Check if email exists
  Future<bool> emailExists(String email, {int? excludeId}) async {
    String where = 'email = ?';
    List<dynamic> whereArgs = [email];
    
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }
  
  /// Get customers by state
  Future<List<Customer>> getByState(String state) async {
    return query(
      where: 'billing_state = ?',
      whereArgs: [state],
      orderBy: 'COALESCE(company_name, contact_name) ASC',
    );
  }
}