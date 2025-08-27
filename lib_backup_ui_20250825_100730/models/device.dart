import 'base_model.dart';

class Device extends BaseModel {
  final String barcode;
  final int propertyId;
  final int deviceTypeId;
  final int? manufacturerId;
  final String? modelNumber;
  final String? serialNumber;
  final DateTime? installationDate;
  final String? locationDescription;
  final String? addressNum;
  final String? panelAddress;
  final int? subtypeId;
  final String? replacementModel;
  final bool needsReplacement;
  final String? replacementReason;
  final String? photoPath;

  Device({
    super.id,
    super.serverId,
    required this.barcode,
    required this.propertyId,
    required this.deviceTypeId,
    this.manufacturerId,
    this.modelNumber,
    this.serialNumber,
    this.installationDate,
    this.locationDescription,
    this.addressNum,
    this.panelAddress,
    this.subtypeId,
    this.replacementModel,
    this.needsReplacement = false,
    this.replacementReason,
    this.photoPath,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  String? get deviceTypeName {
    // You'll need to fetch this from device_types table or store it in the model
    return null; // Temporary fix
  }

  /// Create Device from SQLite map
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      barcode: map['barcode'] as String,
      propertyId: map['property_id'] as int,
      deviceTypeId: map['device_type_id'] as int,
      manufacturerId: map['manufacturer_id'] as int?,
      modelNumber: map['model_number'] as String?,
      serialNumber: map['serial_number'] as String?,
      installationDate: BaseModel.parseDateTime(map['installation_date'] as String?),
      locationDescription: map['location_description'] as String?,
      addressNum: map['address_num'] as String?,
      panelAddress: map['panel_address'] as String?,
      subtypeId: map['subtype_id'] as int?,
      replacementModel: map['replacement_model'] as String?,
      needsReplacement: map['needs_replacement'] == 1,
      replacementReason: map['replacement_reason'] as String?,
      photoPath: map['photo_path'] as String?,
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
      'barcode': barcode,
      'property_id': propertyId,
      'device_type_id': deviceTypeId,
      'manufacturer_id': manufacturerId,
      'model_number': modelNumber,
      'serial_number': serialNumber,
      'installation_date': BaseModel.formatDateTime(installationDate),
      'location_description': locationDescription,
      'address_num': addressNum,
      'panel_address': panelAddress,
      'subtype_id': subtypeId,
      'replacement_model': replacementModel,
      'needs_replacement': needsReplacement ? 1 : 0,
      'replacement_reason': replacementReason,
      'photo_path': photoPath,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  Device copyWith({
    int? id,
    int? serverId,
    String? barcode,
    int? propertyId,
    int? deviceTypeId,
    int? manufacturerId,
    String? modelNumber,
    String? serialNumber,
    DateTime? installationDate,
    String? locationDescription,
    String? addressNum,
    String? panelAddress,
    int? subtypeId,
    String? replacementModel,
    bool? needsReplacement,
    String? replacementReason,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return Device(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      barcode: barcode ?? this.barcode,
      propertyId: propertyId ?? this.propertyId,
      deviceTypeId: deviceTypeId ?? this.deviceTypeId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      installationDate: installationDate ?? this.installationDate,
      locationDescription: locationDescription ?? this.locationDescription,
      addressNum: addressNum ?? this.addressNum,
      panelAddress: panelAddress ?? this.panelAddress,
      subtypeId: subtypeId ?? this.subtypeId,
      replacementModel: replacementModel ?? this.replacementModel,
      needsReplacement: needsReplacement ?? this.needsReplacement,
      replacementReason: replacementReason ?? this.replacementReason,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Get age of device in years
  int? get ageInYears {
    if (installationDate == null) return null;
    return DateTime.now().difference(installationDate!).inDays ~/ 365;
  }

  /// Check if device is old (> 10 years)
  bool get isOld {
    final age = ageInYears;
    return age != null && age > 10;
  }

  /// Check if photo exists
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  @override
  String toString() => 'Device(barcode: $barcode, location: $locationDescription)';
}