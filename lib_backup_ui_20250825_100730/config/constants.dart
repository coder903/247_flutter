class AppConstants {
  // API Configuration
  static const String defaultApiUrl = 'http://localhost:5000';
  static const String apiVersion = '/api/v1';
  
  // Battery Test Constants
  static const double batteryPassThreshold = 0.85; // 85% rule
  static const List<double> commonAmpHourRatings = [7, 12, 18, 26, 35, 55, 100];
  
  // Inspection Types
  static const List<String> inspectionTypes = [
    'Annual',
    'Semi-Annual',
    'Quarterly',
    'Monthly',
    'Special',
  ];
  
  // Device Test Results
  static const List<String> testResults = [
    'Pass',
    'Fail',
    'Not Tested',
  ];
  
  // Service Ticket Status
  static const List<String> ticketStatuses = [
    'Open',
    'In Progress',
    'Completed',
    'Cancelled',
  ];
  
  // Sync Status
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';
  static const String syncModified = 'modified';
  static const String syncConflict = 'conflict';
  
  // Storage Keys
  static const String keyApiUrl = 'api_url';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyDeviceId = 'device_id';
  static const String keyLastSync = 'last_sync';
}