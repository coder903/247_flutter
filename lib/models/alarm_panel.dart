import 'base_model.dart';

class AlarmPanel extends BaseModel {
  final String name;
  final int? buildingId;
  final int? customerId;
  final String? specificLocation;
  final String? qrCode;
  final String? qrAccessKey;
  
  // Monitoring Information
  final String? monitoringOrg;
  final String? monitoringPhone;
  final String? monitoringEmail;
  final String? accountNumber;
  final String? phoneLine1;
  final String? phoneLine2;
  final String transmissionMeans;
  
  // System Information
  final String? controlUnitManufacturer;
  final String? controlUnitModel;
  final String? firmwareRevision;
  
  // Power Information
  final String primaryVoltage;
  final int primaryAmps;
  final String overcurrentProtectionType;
  final int overcurrentAmps;
  final String? disconnectingMeansLocation;

  AlarmPanel({
    super.id,
    super.serverId,
    required this.name,
    this.buildingId,
    this.customerId,
    this.specificLocation,
    this.qrCode,
    this.qrAccessKey,
    this.monitoringOrg,
    this.monitoringPhone,
    this.monitoringEmail,
    this.accountNumber,
    this.phoneLine1,
    this.phoneLine2,
    this.transmissionMeans = 'DACT',
    this.controlUnitManufacturer,
    this.controlUnitModel,
    this.firmwareRevision,
    this.primaryVoltage = '120VAC',
    this.primaryAmps = 20,
    this.overcurrentProtectionType = 'Breaker',
    this.overcurrentAmps = 20,
    this.disconnectingMeansLocation,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Create AlarmPanel from SQLite map
  factory AlarmPanel.fromMap(Map<String, dynamic> map) {
    return AlarmPanel(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      name: map['name'] as String,
      buildingId: map['building_id'] as int?,
      customerId: map['customer_id'] as int?,
      specificLocation: map['specific_location'] as String?,
      qrCode: map['qr_code'] as String?,
      qrAccessKey: map['qr_access_key'] as String?,
      monitoringOrg: map['monitoring_org'] as String?,
      monitoringPhone: map['monitoring_phone'] as String?,
      monitoringEmail: map['monitoring_email'] as String?,
      accountNumber: map['account_number'] as String?,
      phoneLine1: map['phone_line_1'] as String?,
      phoneLine2: map['phone_line_2'] as String?,
      transmissionMeans: map['transmission_means'] as String? ?? 'DACT',
      controlUnitManufacturer: map['control_unit_manufacturer'] as String?,
      controlUnitModel: map['control_unit_model'] as String?,
      firmwareRevision: map['firmware_revision'] as String?,
      primaryVoltage: map['primary_voltage'] as String? ?? '120VAC',
      primaryAmps: map['primary_amps'] as int? ?? 20,
      overcurrentProtectionType: map['overcurrent_protection_type'] as String? ?? 'Breaker',
      overcurrentAmps: map['overcurrent_amps'] as int? ?? 20,
      disconnectingMeansLocation: map['disconnecting_means_location'] as String?,
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
      'name': name,
      'building_id': buildingId,
      'customer_id': customerId,
      'specific_location': specificLocation,
      'qr_code': qrCode,
      'qr_access_key': qrAccessKey,
      'monitoring_org': monitoringOrg,
      'monitoring_phone': monitoringPhone,
      'monitoring_email': monitoringEmail,
      'account_number': accountNumber,
      'phone_line_1': phoneLine1,
      'phone_line_2': phoneLine2,
      'transmission_means': transmissionMeans,
      'control_unit_manufacturer': controlUnitManufacturer,
      'control_unit_model': controlUnitModel,
      'firmware_revision': firmwareRevision,
      'primary_voltage': primaryVoltage,
      'primary_amps': primaryAmps,
      'overcurrent_protection_type': overcurrentProtectionType,
      'overcurrent_amps': overcurrentAmps,
      'disconnecting_means_location': disconnectingMeansLocation,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  AlarmPanel copyWith({
    int? id,
    int? serverId,
    String? name,
    int? buildingId,
    int? customerId,
    String? specificLocation,
    String? qrCode,
    String? qrAccessKey,
    String? monitoringOrg,
    String? monitoringPhone,
    String? monitoringEmail,
    String? accountNumber,
    String? phoneLine1,
    String? phoneLine2,
    String? transmissionMeans,
    String? controlUnitManufacturer,
    String? controlUnitModel,
    String? firmwareRevision,
    String? primaryVoltage,
    int? primaryAmps,
    String? overcurrentProtectionType,
    int? overcurrentAmps,
    String? disconnectingMeansLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return AlarmPanel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      buildingId: buildingId ?? this.buildingId,
      customerId: customerId ?? this.customerId,
      specificLocation: specificLocation ?? this.specificLocation,
      qrCode: qrCode ?? this.qrCode,
      qrAccessKey: qrAccessKey ?? this.qrAccessKey,
      monitoringOrg: monitoringOrg ?? this.monitoringOrg,
      monitoringPhone: monitoringPhone ?? this.monitoringPhone,
      monitoringEmail: monitoringEmail ?? this.monitoringEmail,
      accountNumber: accountNumber ?? this.accountNumber,
      phoneLine1: phoneLine1 ?? this.phoneLine1,
      phoneLine2: phoneLine2 ?? this.phoneLine2,
      transmissionMeans: transmissionMeans ?? this.transmissionMeans,
      controlUnitManufacturer: controlUnitManufacturer ?? this.controlUnitManufacturer,
      controlUnitModel: controlUnitModel ?? this.controlUnitModel,
      firmwareRevision: firmwareRevision ?? this.firmwareRevision,
      primaryVoltage: primaryVoltage ?? this.primaryVoltage,
      primaryAmps: primaryAmps ?? this.primaryAmps,
      overcurrentProtectionType: overcurrentProtectionType ?? this.overcurrentProtectionType,
      overcurrentAmps: overcurrentAmps ?? this.overcurrentAmps,
      disconnectingMeansLocation: disconnectingMeansLocation ?? this.disconnectingMeansLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Get panel description
  String get panelDescription {
    if (controlUnitManufacturer != null && controlUnitModel != null) {
      return '$controlUnitManufacturer $controlUnitModel';
    }
    return 'Unknown Panel';
  }

  /// Check if QR code is configured
  bool get hasQrCode => qrCode != null && qrAccessKey != null;

  @override
  String toString() => 'AlarmPanel(id: $id, name: $name)';
}