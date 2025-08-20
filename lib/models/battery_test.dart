import 'base_model.dart';
import '../config/constants.dart';

class BatteryTest extends BaseModel {
  final int inspectionId;
  final String? barcode;
  final String? position; // B1, B2, etc.
  final String? serialNumber;
  final double ratedAmpHours;
  final double? voltageReading;
  final double currentReading;
  final double? temperatureF;
  final double? minCurrentRequired;
  final bool? passed;
  final String? panelConnection;
  final String? notes;
  final String? photoPath;
  final String? videoPath;

  BatteryTest({
    super.id,
    super.serverId,
    required this.inspectionId,
    this.barcode,
    this.position,
    this.serialNumber,
    required this.ratedAmpHours,
    this.voltageReading,
    required this.currentReading,
    this.temperatureF,
    double? minCurrentRequired,
    bool? passed,
    this.panelConnection,
    this.notes,
    this.photoPath,
    this.videoPath,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  })  : minCurrentRequired = minCurrentRequired ?? (ratedAmpHours * AppConstants.batteryPassThreshold),
        passed = passed ?? (currentReading >= (minCurrentRequired ?? (ratedAmpHours * AppConstants.batteryPassThreshold)));

  /// Create BatteryTest from SQLite map
  factory BatteryTest.fromMap(Map<String, dynamic> map) {
    final ratedAmpHours = map['rated_amp_hours'] as double;
    final currentReading = map['current_reading'] as double;
    final minCurrentRequired = map['min_current_required'] as double?;
    
    return BatteryTest(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      inspectionId: map['inspection_id'] as int,
      barcode: map['barcode'] as String?,
      position: map['position'] as String?,
      serialNumber: map['serial_number'] as String?,
      ratedAmpHours: ratedAmpHours,
      voltageReading: map['voltage_reading'] as double?,
      currentReading: currentReading,
      temperatureF: map['temperature_f'] as double?,
      minCurrentRequired: minCurrentRequired,
      passed: map['passed'] == null ? null : map['passed'] == 1,
      panelConnection: map['panel_connection'] as String?,
      notes: map['notes'] as String?,
      photoPath: map['photo_path'] as String?,
      videoPath: map['video_path'] as String?,
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
      'inspection_id': inspectionId,
      'barcode': barcode,
      'position': position,
      'serial_number': serialNumber,
      'rated_amp_hours': ratedAmpHours,
      'voltage_reading': voltageReading,
      'current_reading': currentReading,
      'temperature_f': temperatureF,
      'min_current_required': minCurrentRequired,
      'passed': passed == null ? null : (passed! ? 1 : 0),
      'panel_connection': panelConnection,
      'notes': notes,
      'photo_path': photoPath,
      'video_path': videoPath,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  BatteryTest copyWith({
    int? id,
    int? serverId,
    int? inspectionId,
    String? barcode,
    String? position,
    String? serialNumber,
    double? ratedAmpHours,
    double? voltageReading,
    double? currentReading,
    double? temperatureF,
    double? minCurrentRequired,
    bool? passed,
    String? panelConnection,
    String? notes,
    String? photoPath,
    String? videoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return BatteryTest(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      inspectionId: inspectionId ?? this.inspectionId,
      barcode: barcode ?? this.barcode,
      position: position ?? this.position,
      serialNumber: serialNumber ?? this.serialNumber,
      ratedAmpHours: ratedAmpHours ?? this.ratedAmpHours,
      voltageReading: voltageReading ?? this.voltageReading,
      currentReading: currentReading ?? this.currentReading,
      temperatureF: temperatureF ?? this.temperatureF,
      minCurrentRequired: minCurrentRequired ?? this.minCurrentRequired,
      passed: passed ?? this.passed,
      panelConnection: panelConnection ?? this.panelConnection,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Recalculate pass/fail based on current values
  BatteryTest recalculate() {
    final newMinRequired = ratedAmpHours * AppConstants.batteryPassThreshold;
    final newPassed = currentReading >= newMinRequired;
    
    return copyWith(
      minCurrentRequired: newMinRequired,
      passed: newPassed,
    );
  }

  /// Get percentage of rated capacity
  double get percentageOfRated => (currentReading / ratedAmpHours) * 100;

  /// Get display text for position
  String get displayPosition => position ?? 'Unknown';

  /// Get pass/fail text
  String get passFailText => passed == true ? 'PASS' : 'FAIL';

  /// Check if temperature is high
  bool get isHighTemperature => temperatureF != null && temperatureF! > 95;

  /// Get formatted readings
  String get formattedReadings {
    return '${currentReading.toStringAsFixed(2)} / ${minCurrentRequired?.toStringAsFixed(2) ?? 'N/A'} Ah';
  }

  /// Check if has media (photo or video)
  bool get hasMedia => (photoPath != null && photoPath!.isNotEmpty) || 
                       (videoPath != null && videoPath!.isNotEmpty);

  @override
  String toString() => 'BatteryTest(position: $position, passed: $passed)';
}