// lib/models/base_model.dart

/// Base model class that provides common functionality for all models
abstract class BaseModel {
  final int? id;
  final int? serverId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final bool deleted;

  BaseModel({
    this.id,
    this.serverId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
    this.deleted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert database timestamp string to DateTime
  static DateTime? parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Convert DateTime to database timestamp string
  static String? formatDateTime(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String();
  }

  /// Check if this record needs syncing
  bool get needsSync => syncStatus == 'pending' || syncStatus == 'modified';

  /// Check if this record exists on server
  bool get existsOnServer => serverId != null;
}