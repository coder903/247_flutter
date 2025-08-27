import 'base_model.dart';

class Building extends BaseModel {
  final String buildingName;
  final String? buildingCode;
  final String? address;
  final String? address2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? buildingType;
  final int? floors;
  final int? units;
  final double? latitude;
  final double? longitude;
  final String? accessNotes;
  final String? contactName;
  final String? contactPhone;
  final String? managementCompany;
  final String? managementPhone;

  Building({
    super.id,
    super.serverId,
    required this.buildingName,
    this.buildingCode,
    this.address,
    this.address2,
    this.city,
    this.state,
    this.zipCode,
    this.buildingType,
    this.floors,
    this.units,
    this.latitude,
    this.longitude,
    this.accessNotes,
    this.contactName,
    this.contactPhone,
    this.managementCompany,
    this.managementPhone,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Create Building from SQLite map
  factory Building.fromMap(Map<String, dynamic> map) {
    return Building(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      buildingName: map['building_name'] as String,
      buildingCode: map['building_code'] as String?,
      address: map['address'] as String?,
      address2: map['address2'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zip_code'] as String?,
      buildingType: map['building_type'] as String?,
      floors: map['floors'] as int?,
      units: map['units'] as int?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      accessNotes: map['access_notes'] as String?,
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
      managementCompany: map['management_company'] as String?,
      managementPhone: map['management_phone'] as String?,
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
      'building_name': buildingName,
      'building_code': buildingCode,
      'address': address,
      'address2': address2,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'building_type': buildingType,
      'floors': floors,
      'units': units,
      'latitude': latitude,
      'longitude': longitude,
      'access_notes': accessNotes,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'management_company': managementCompany,
      'management_phone': managementPhone,
      'created_at': BaseModel.formatDateTime(createdAt),
      'updated_at': BaseModel.formatDateTime(updatedAt),
      'sync_status': syncStatus,
      'deleted': deleted ? 1 : 0,
    };
  }

  /// Create copy with updated fields
  Building copyWith({
    int? id,
    int? serverId,
    String? buildingName,
    String? buildingCode,
    String? address,
    String? address2,
    String? city,
    String? state,
    String? zipCode,
    String? buildingType,
    int? floors,
    int? units,
    double? latitude,
    double? longitude,
    String? accessNotes,
    String? contactName,
    String? contactPhone,
    String? managementCompany,
    String? managementPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return Building(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      buildingName: buildingName ?? this.buildingName,
      buildingCode: buildingCode ?? this.buildingCode,
      address: address ?? this.address,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      buildingType: buildingType ?? this.buildingType,
      floors: floors ?? this.floors,
      units: units ?? this.units,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accessNotes: accessNotes ?? this.accessNotes,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      managementCompany: managementCompany ?? this.managementCompany,
      managementPhone: managementPhone ?? this.managementPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Get display address
  String get fullAddress {
    final parts = <String>[
      if (address != null) address!,
      if (address2 != null) address2!,
      if (city != null) city!,
      if (state != null && zipCode != null) '$state $zipCode',
    ];
    return parts.join(', ');
  }

  /// Get display name with code if available
  String get displayName {
    if (buildingCode != null) {
      return '$buildingName ($buildingCode)';
    }
    return buildingName;
  }

  @override
  String toString() => 'Building(id: $id, name: $buildingName)';
}