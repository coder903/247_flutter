/// Device Category (Initiating, Alarm, Indicating, etc.)
class DeviceCategory {
  final int id;
  final String categoryName;

  DeviceCategory({
    required this.id,
    required this.categoryName,
  });

  factory DeviceCategory.fromMap(Map<String, dynamic> map) {
    return DeviceCategory(
      id: map['id'] as int,
      categoryName: map['category_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
    };
  }

  @override
  String toString() => categoryName;
}

/// Device Type (Smoke Detector, Horn/Strobe, etc.)
class DeviceType {
  final int id;
  final int categoryId;
  final String deviceTypeName;

  DeviceType({
    required this.id,
    required this.categoryId,
    required this.deviceTypeName,
  });

  factory DeviceType.fromMap(Map<String, dynamic> map) {
    return DeviceType(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      deviceTypeName: map['device_type_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'device_type_name': deviceTypeName,
    };
  }

  @override
  String toString() => deviceTypeName;
}

/// Manufacturer
class Manufacturer {
  final int id;
  final String manufacturerName;

  Manufacturer({
    required this.id,
    required this.manufacturerName,
  });

  factory Manufacturer.fromMap(Map<String, dynamic> map) {
    return Manufacturer(
      id: map['id'] as int,
      manufacturerName: map['manufacturer_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturer_name': manufacturerName,
    };
  }

  @override
  String toString() => manufacturerName;
}

/// Device SubType (LED, Photoelectric, Dry Chemical, etc.)
class DeviceSubtype {
  final int id;
  final String subtypeName;

  DeviceSubtype({
    required this.id,
    required this.subtypeName,
  });

  factory DeviceSubtype.fromMap(Map<String, dynamic> map) {
    return DeviceSubtype(
      id: map['id'] as int,
      subtypeName: map['subtype_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subtype_name': subtypeName,
    };
  }

  @override
  String toString() => subtypeName;
}