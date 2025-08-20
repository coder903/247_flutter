import 'base_model.dart';

class ComponentTest extends BaseModel {
  final int inspectionId;
  final int deviceId;
  final String? testResult; // Pass, Fail, Not Tested
  
  // Device-specific test fields
  final String? sensitivity; // For smoke detectors
  final String? decibelLevel; // For horns/strobes
  final DateTime? servicedDate; // For fire extinguishers
  final DateTime? hydroDate; // For fire extinguishers
  final String? size; // For fire extinguishers (e.g., "20 lbs")
  final bool? check24hrPost; // For emergency lights
  
  final String? notes;
  final String? photoPath;
  final String? videoPath;

  ComponentTest({
    super.id,
    super.serverId,
    required this.inspectionId,
    required this.deviceId,
    this.testResult,
    this.sensitivity,
    this.decibelLevel,
    this.servicedDate,
    this.hydroDate,
    this.size,
    this.check24hrPost,
    this.notes,
    this.photoPath,
    this.videoPath,
    super.createdAt,
    super.updatedAt,
    super.syncStatus,
    super.deleted,
  });

  /// Create ComponentTest from SQLite map
  factory ComponentTest.fromMap(Map<String, dynamic> map) {
    return ComponentTest(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      inspectionId: map['inspection_id'] as int,
      deviceId: map['device_id'] as int,
      testResult: map['test_result'] as String?,
      sensitivity: map['sensitivity'] as String?,
      decibelLevel: map['decibel_level'] as String?,
      servicedDate: BaseModel.parseDateTime(map['serviced_date'] as String?),
      hydroDate: BaseModel.parseDateTime(map['hydro_date'] as String?),
      size: map['size'] as String?,
      check24hrPost: map['check_24hr_post'] == null ? null : map['check_24hr_post'] == 1,
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
      'device_id': deviceId,
      'test_result': testResult,
      'sensitivity': sensitivity,
      'decibel_level': decibelLevel,
      'serviced_date': BaseModel.formatDateTime(servicedDate),
      'hydro_date': BaseModel.formatDateTime(hydroDate),
      'size': size,
      'check_24hr_post': check24hrPost == null ? null : (check24hrPost! ? 1 : 0),
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
  ComponentTest copyWith({
    int? id,
    int? serverId,
    int? inspectionId,
    int? deviceId,
    String? testResult,
    String? sensitivity,
    String? decibelLevel,
    DateTime? servicedDate,
    DateTime? hydroDate,
    String? size,
    bool? check24hrPost,
    String? notes,
    String? photoPath,
    String? videoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? deleted,
  }) {
    return ComponentTest(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      inspectionId: inspectionId ?? this.inspectionId,
      deviceId: deviceId ?? this.deviceId,
      testResult: testResult ?? this.testResult,
      sensitivity: sensitivity ?? this.sensitivity,
      decibelLevel: decibelLevel ?? this.decibelLevel,
      servicedDate: servicedDate ?? this.servicedDate,
      hydroDate: hydroDate ?? this.hydroDate,
      size: size ?? this.size,
      check24hrPost: check24hrPost ?? this.check24hrPost,
      notes: notes ?? this.notes,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deleted: deleted ?? this.deleted,
    );
  }

  /// Check if test passed
  bool get passed => testResult?.toLowerCase() == 'pass';

  /// Check if test failed
  bool get failed => testResult?.toLowerCase() == 'fail';

  /// Check if not tested
  bool get notTested => testResult?.toLowerCase() == 'not tested' || testResult == null;

  /// Check if fire extinguisher needs service
  bool get needsService {
    if (servicedDate == null) return true;
    final yearsSinceService = DateTime.now().difference(servicedDate!).inDays / 365;
    return yearsSinceService >= 1; // Annual service required
  }

  /// Check if fire extinguisher needs hydrostatic test
  bool get needsHydroTest {
    if (hydroDate == null) return true;
    final yearsSinceHydro = DateTime.now().difference(hydroDate!).inDays / 365;
    return yearsSinceHydro >= 5; // 5-year hydro test for most extinguishers
  }

  /// Get display text for 24hr post check
  String get check24hrPostText {
    if (check24hrPost == null) return 'N/A';
    return check24hrPost! ? 'Yes' : 'No';
  }

  /// Check if has media
  bool get hasMedia => (photoPath != null && photoPath!.isNotEmpty) || 
                       (videoPath != null && videoPath!.isNotEmpty);

  /// Check if has any test data
  bool get hasTestData {
    return testResult != null ||
           sensitivity != null ||
           decibelLevel != null ||
           servicedDate != null ||
           hydroDate != null ||
           size != null ||
           check24hrPost != null ||
           notes != null;
  }

  @override
  String toString() => 'ComponentTest(deviceId: $deviceId, result: $testResult)';
}