// lib/repositories/service_ticket_repository.dart

import 'base_repository.dart';
import '../models/service_ticket.dart';
import '../database/database_helper.dart';

class ServiceTicketRepository extends BaseRepository<ServiceTicket> {
  static final ServiceTicketRepository _instance = ServiceTicketRepository._internal();
  factory ServiceTicketRepository() => _instance;
  ServiceTicketRepository._internal();
  
  @override
  String get tableName => 'service_tickets';
  
  @override
  ServiceTicket fromMap(Map<String, dynamic> map) => ServiceTicket.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(ServiceTicket model) => model.toMap();
  
  /// Override insert to generate ticket number if needed
  @override
  Future<ServiceTicket> insert(ServiceTicket model) async {
    ServiceTicket ticketToInsert = model;
    
    // Generate ticket number if not provided
    if (model.ticketNumber == null) {
      ticketToInsert = model.copyWith(
        ticketNumber: model.generateTicketNumber(),
      );
    }
    
    return super.insert(ticketToInsert);
  }
  
  /// Get tickets by property
  Future<List<ServiceTicket>> getByProperty(int propertyId) async {
    return query(
      where: 'alarm_panel_id = ?',
      whereArgs: [propertyId],
      orderBy: 'created_at DESC',
    );
  }
  
  /// Get tickets by status
  Future<List<ServiceTicket>> getByStatus(String status) async {
    return query(
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }
  
  /// Get open tickets
  Future<List<ServiceTicket>> getOpenTickets() async {
    return query(
      where: "status IN ('Open', 'In Progress')",
      orderBy: 'created_at ASC',
    );
  }
  
  /// Get tickets waiting for parts
  Future<List<ServiceTicket>> getTicketsWaitingForParts() async {
    return query(
      where: 'parts_ordered = 1 AND parts_received = 0',
      orderBy: 'created_at ASC',
    );
  }
  
  /// Get tickets with property details
  Future<List<Map<String, dynamic>>> getTicketsWithDetails({
    String? status,
    int? propertyId,
    bool? waitingForParts,
  }) async {
    String sql = '''
      SELECT 
        st.*,
        p.name as property_name,
        p.account_number,
        b.building_name,
        b.address as building_address,
        c.company_name,
        c.contact_name as customer_name
      FROM service_tickets st
      LEFT JOIN alarm_panels p ON st.alarm_panel_id = p.id
      LEFT JOIN buildings b ON p.building_id = b.id
      LEFT JOIN customers c ON p.customer_id = c.id
      WHERE st.deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (status != null) {
      sql += ' AND st.status = ?';
      args.add(status);
    }
    
    if (propertyId != null) {
      sql += ' AND st.alarm_panel_id = ?';
      args.add(propertyId);
    }
    
    if (waitingForParts == true) {
      sql += ' AND st.parts_ordered = 1 AND st.parts_received = 0';
    }
    
    sql += ' ORDER BY st.created_at DESC';
    
    return rawQuery(sql, args);
  }
  
  /// Search tickets
  Future<List<Map<String, dynamic>>> search(String query) async {
    final searchQuery = '%$query%';
    
    const sql = '''
      SELECT 
        st.*,
        p.name as property_name,
        b.building_name
      FROM service_tickets st
      LEFT JOIN alarm_panels p ON st.alarm_panel_id = p.id
      LEFT JOIN buildings b ON p.building_id = b.id
      WHERE st.deleted = 0 AND (
        st.ticket_number LIKE ? OR 
        st.issue_description LIKE ? OR 
        st.troubleshooting_notes LIKE ? OR
        st.parts_needed LIKE ? OR
        p.name LIKE ?
      )
      ORDER BY st.created_at DESC
    ''';
    
    return rawQuery(sql, [searchQuery, searchQuery, searchQuery, searchQuery, searchQuery]);
  }
  
  /// Get ticket statistics
  Future<Map<String, dynamic>> getTicketStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String sql = '''
      SELECT 
        COUNT(*) as total_tickets,
        SUM(CASE WHEN status = 'Open' THEN 1 ELSE 0 END) as open_count,
        SUM(CASE WHEN status = 'In Progress' THEN 1 ELSE 0 END) as in_progress_count,
        SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed_count,
        SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) as cancelled_count,
        SUM(CASE WHEN parts_ordered = 1 AND parts_received = 0 THEN 1 ELSE 0 END) as waiting_parts_count,
        AVG(CASE WHEN status = 'Completed' AND completed_at IS NOT NULL THEN 
          julianday(completed_at) - julianday(created_at) 
          ELSE NULL END) as avg_completion_days
      FROM service_tickets
      WHERE deleted = 0
    ''';
    
    List<dynamic> args = [];
    
    if (startDate != null) {
      sql += ' AND created_at >= ?';
      args.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      sql += ' AND created_at <= ?';
      args.add(endDate.toIso8601String());
    }
    
    final results = await rawQuery(sql, args);
    return results.first;
  }
  
  /// Update ticket status
  Future<ServiceTicket> updateStatus(int ticketId, String newStatus) async {
    final ticket = await getById(ticketId);
    if (ticket == null) {
      throw Exception('Ticket not found');
    }
    
    DateTime? completedAt;
    if (newStatus.toLowerCase() == 'completed') {
      completedAt = DateTime.now();
    }
    
    final updated = ticket.copyWith(
      status: newStatus,
      completedAt: completedAt,
    );
    
    return update(updated);
  }
  
  /// Update parts status
  Future<ServiceTicket> updatePartsStatus({
    required int ticketId,
    bool? partsOrdered,
    bool? partsReceived,
    String? partsNeeded,
  }) async {
    final ticket = await getById(ticketId);
    if (ticket == null) {
      throw Exception('Ticket not found');
    }
    
    final updated = ticket.copyWith(
      partsOrdered: partsOrdered ?? ticket.partsOrdered,
      partsReceived: partsReceived ?? ticket.partsReceived,
      partsNeeded: partsNeeded ?? ticket.partsNeeded,
    );
    
    return update(updated);
  }
  
  /// Get tickets created from inspection
  Future<List<ServiceTicket>> getTicketsFromInspection(int inspectionId) async {
    // This would require adding inspection_id to service_tickets table
    // For now, we can get tickets created around the same time
    const sql = '''
      SELECT st.*
      FROM service_tickets st
      INNER JOIN inspections i ON st.alarm_panel_id = i.alarm_panel_id
      WHERE i.id = ? 
        AND st.deleted = 0
        AND ABS(julianday(st.created_at) - julianday(i.completion_datetime)) < 1
      ORDER BY st.created_at ASC
    ''';
    
    final maps = await rawQuery(sql, [inspectionId]);
    return maps.map((map) => ServiceTicket.fromMap(map)).toList();
  }
  
  /// Create ticket from failed test
  Future<ServiceTicket> createFromFailedTest({
    required int alarmPanelId,
    required String deviceType,
    required String location,
    required String issue,
    String? partsNeeded,
  }) async {
    final ticket = ServiceTicket(
      alarmPanelId: alarmPanelId,
      issueDescription: 'Failed $deviceType test at $location. $issue',
      partsNeeded: partsNeeded,
      status: 'Open',
    );
    
    return insert(ticket);
  }
}