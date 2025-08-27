// lib/models/base_model.dart
abstract class BaseModel {
  final int? id;
  final int? serverId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool deleted;

  BaseModel({
    this.id,
    this.serverId,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.deleted = false,
  });

  /// Convert model to map for database storage
  Map<String, dynamic> toMap();

  /// Helper method to parse datetime from string
  static DateTime? parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to format datetime to string
  static String? formatDateTime(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}