// lib/models/inspection.dart

import 'base_model.dart';

class Inspection extends BaseModel {
  final int propertyId;
  final String? inspectorName;
  final int? inspectorUserId;
  final DateTime? startDatetime;
  final DateTime? completionDatetime;
  final String? inspectionType;
  final DateTime? inspectionDate;
  final String? defects;
  final bool isComplete;
  final double? panelTemperatureF;
  
  // Additional fields for the summary screen
  final String? notes;
  final String? overallResult;  // 'Pass' or 'Fail'
  final String? status;  // 'In Progress', 'Completed'
  
  // Statistics fields
  final int? batteryCount;
  final int? batteryPassed;
  final int? componentCount;
  final int? componentPassed;

  Inspection({
    super.id,
    super.serverId,
    required this.propertyId,
    this.inspectorName,
    this.inspectorUserId,
    this.startDatetime,
    this.completionDatetime,
    this.inspectionType,
    this.inspectionDate,
    this.defects,
    this.isComplete = false,
    this.panelTemperatureF,
    this.notes,
    this.overallResult,
    this.status,
    this.batteryCount,
    this.batteryPassed,
    this.componentCount,
    this.componentPassed,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Getter for inspectorId (alias for backwards compatibility)
  int? get inspectorId => inspectorUserId;

  /// Get if inspection passed (convenience getter)
  bool? get passed => overallResult == 'Pass' ? true : overallResult == 'Fail' ? false : null;
  
  /// Get completed at (alias for completionDatetime)
  DateTime? get completedAt => completionDatetime;

  /// Create Inspection from SQLite map
  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      propertyId: map['property_id'] as int,
      inspectorName: map['inspector_name'] as String?,
      inspectorUserId: map['inspector_user_id'] as int?,
      startDatetime: BaseModel.parseDateTime(map['start_datetime'] as String?),
      completionDatetime: BaseModel.parseDateTime(map['completion_datetime'] as String?),
      inspectionType: map['inspection_type'] as String?,
      inspectionDate: BaseModel.parseDateTime(map['inspection_date'] as String?),
      defects: map['defects'] as String?,
      isComplete: map['is_complete'] == 1,
      panelTemperatureF: map['panel_temperature_f'] as double?,
      notes: map['notes'] as String?,
      overallResult: map['overall_result'] as String?,
      status: map['status'] as String?,
      batteryCount: map['battery_count'] as int?,
      batteryPassed: map['battery_passed'] as int?,
      componentCount: map['component_count'] as int?,
      componentPassed: map['component_passed'] as int?,
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
      'property_id': propertyId,
      'inspector_name': inspectorName,
      'inspector_user_id': inspectorUserId,
      'start_datetime': BaseModel.formatDateTime(startDatetime),
      'completion_datetime': BaseModel.formatDateTime(completionDatetime),
      'inspection_type': inspectionType,
      'inspection_date': BaseModel.formatDateTime(inspectionDate),
      'defects': defects,
      'is_complete': isComplete ? 1 : 0,
      'panel_temperature_f': panelTemperatureF,
      'notes': notes,
      'overall_result': overallResult,
      'status': status,
      'battery_count': batteryCount,
      'battery_passed': batteryPassed,
      'component_count': componentCount,
      'component_passed': componentPassed,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  Inspection copyWith({
    int? id,
    int? serverId,
    int? propertyId,
    String? inspectorName,
    int? inspectorUserId,
    DateTime? startDatetime,
    DateTime? completionDatetime,
    String? inspectionType,
    DateTime? inspectionDate,
    String? defects,
    bool? isComplete,
    double? panelTemperatureF,
    String? notes,
    String? overallResult,
    String? status,
    int? batteryCount,
    int? batteryPassed,
    int? componentCount,
    int? componentPassed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return Inspection(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      propertyId: propertyId ?? this.propertyId,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorUserId: inspectorUserId ?? this.inspectorUserId,
      startDatetime: startDatetime ?? this.startDatetime,
      completionDatetime: completionDatetime ?? this.completionDatetime,
      inspectionType: inspectionType ?? this.inspectionType,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      defects: defects ?? this.defects,
      isComplete: isComplete ?? this.isComplete,
      panelTemperatureF: panelTemperatureF ?? this.panelTemperatureF,
      notes: notes ?? this.notes,
      overallResult: overallResult ?? this.overallResult,
      status: status ?? this.status,
      batteryCount: batteryCount ?? this.batteryCount,
      batteryPassed: batteryPassed ?? this.batteryPassed,
      componentCount: componentCount ?? this.componentCount,
      componentPassed: componentPassed ?? this.componentPassed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Get duration of inspection
  Duration? get duration {
    if (startDatetime == null || completionDatetime == null) return null;
    return completionDatetime!.difference(startDatetime!);
  }

  /// Get duration in minutes
  int? get durationMinutes => duration?.inMinutes;

  /// Check if inspection is in progress
  bool get isInProgress => startDatetime != null && completionDatetime == null;

  /// Check if temperature is high (warning threshold)
  bool get isHighTemperature => panelTemperatureF != null && panelTemperatureF! > 95;

  /// Get display date
  String get displayDate {
    final date = inspectionDate ?? startDatetime ?? createdAt;
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Get status text
  String get statusText {
    if (status != null) return status!;
    if (isComplete) return 'Completed';
    if (isInProgress) return 'In Progress';
    return 'Not Started';
  }

  /// Check if has defects
  bool get hasDefects => defects != null && defects!.isNotEmpty;

  @override
  String toString() => 'Inspection(id: $id, type: $inspectionType, status: $statusText)';
}