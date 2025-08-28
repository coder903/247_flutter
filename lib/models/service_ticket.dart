import 'base_model.dart';

class ServiceTicket extends BaseModel {
  final int alarmPanelId;
  final String? ticketNumber;
  final String? issueDescription;
  final String? troubleshootingNotes;
  final String? partsNeeded;
  final bool partsOrdered;
  final bool partsReceived;
  final String status;
  final DateTime? completedAt;

  ServiceTicket({
    super.id,
    super.serverId,
    required this.alarmPanelId,
    this.ticketNumber,
    this.issueDescription,
    this.troubleshootingNotes,
    this.partsNeeded,
    this.partsOrdered = false,
    this.partsReceived = false,
    this.status = 'Open',
    this.completedAt,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Create ServiceTicket from SQLite map
  factory ServiceTicket.fromMap(Map<String, dynamic> map) {
    return ServiceTicket(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      alarmPanelId: map['alarm_panel_id'] as int,
      ticketNumber: map['ticket_number'] as String?,
      issueDescription: map['issue_description'] as String?,
      troubleshootingNotes: map['troubleshooting_notes'] as String?,
      partsNeeded: map['parts_needed'] as String?,
      partsOrdered: map['parts_ordered'] == 1,
      partsReceived: map['parts_received'] == 1,
      status: map['status'] as String? ?? 'Open',
      completedAt: BaseModel.parseDateTime(map['completed_at'] as String?),
      createdAt: BaseModel.parseDateTime(map['created_at'] as String?),
      updatedAt: BaseModel.parseDateTime(map['updated_at'] as String?),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      deleted: map['deleted'] == 1,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      'alarm_panel_id': alarmPanelId,
      'ticket_number': ticketNumber,
      'issue_description': issueDescription,
      'troubleshooting_notes': troubleshootingNotes,
      'parts_needed': partsNeeded,
      'parts_ordered': partsOrdered ? 1 : 0,
      'parts_received': partsReceived ? 1 : 0,
      'status': status,
      'completed_at': BaseModel.formatDateTime(completedAt),
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  ServiceTicket copyWith({
    int? id,
    int? serverId,
    int? alarmPanelId,
    String? ticketNumber,
    String? issueDescription,
    String? troubleshootingNotes,
    String? partsNeeded,
    bool? partsOrdered,
    bool? partsReceived,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return ServiceTicket(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      alarmPanelId: alarmPanelId ?? this.alarmPanelId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      issueDescription: issueDescription ?? this.issueDescription,
      troubleshootingNotes: troubleshootingNotes ?? this.troubleshootingNotes,
      partsNeeded: partsNeeded ?? this.partsNeeded,
      partsOrdered: partsOrdered ?? this.partsOrdered,
      partsReceived: partsReceived ?? this.partsReceived,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Check if ticket is open
  bool get isOpen => status.toLowerCase() == 'open';

  /// Check if ticket is in progress
  bool get isInProgress => status.toLowerCase() == 'in progress';

  /// Check if ticket is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if ticket is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Check if waiting for parts
  bool get waitingForParts => partsOrdered && !partsReceived;

  /// Check if has parts info
  bool get hasParts => partsNeeded != null && partsNeeded!.isNotEmpty;

  /// Get age of ticket in days
  int get ageInDays => createdAt != null ? DateTime.now().difference(createdAt!).inDays : 0;

  /// Get display age
  String get displayAge {
    final days = ageInDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${days ~/ 7} weeks ago';
    return '${days ~/ 30} months ago';
  }

  /// Get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return '#FF5252'; // Red
      case 'in progress':
        return '#FFA726'; // Orange
      case 'completed':
        return '#66BB6A'; // Green
      case 'cancelled':
        return '#BDBDBD'; // Gray
      default:
        return '#757575'; // Default gray
    }
  }

  /// Generate ticket number if not exists
  String generateTicketNumber() {
    if (ticketNumber != null) return ticketNumber!;
    final now = DateTime.now();
    return 'T${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 10000}';
  }

  @override
  String toString() => 'ServiceTicket(number: $ticketNumber, status: $status)';
}