// lib/config/app_config.dart
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://your-api-domain.com'; // Replace with your actual API URL
  static const String apiVersion = 'v1';
  
  // Development/Production flags
  static const bool isDevelopment = true; // Set to false for production
  
  // Database Configuration
  static const String databaseName = 'fire_inspection.db';
  static const int databaseVersion = 2;
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxSyncRetries = 5;
  static const int syncBatchSize = 50;
  
  // Photo/Video Configuration
  static const int maxPhotoWidth = 1920;
  static const int maxPhotoHeight = 1080;
  static const int photoQuality = 85;
  static const int maxVideoSizeInMB = 100;
  
  // Barcode Configuration
  static const int minBarcodeLength = 8;
  static const int maxBarcodeLength = 12;
  static const String barcodePrefix = 'FI'; // Fire Inspection prefix
  
  // Battery Test Configuration
  static const double batteryPassPercentage = 0.85; // 85% of rated amp hours
  static const List<double> ratedAmpHours = [7, 12, 18, 26, 35, 55, 100];
  
  // PDF Configuration
  static const String companyName = 'Your Company Name';
  static const String companyLogo = 'assets/images/logo.png';
  static const String reportFooter = 'This report complies with NFPA 72 standards';
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enablePhotoCapture = true;
  static const bool enableVideoCapture = true;
  static const bool enableBarcodeScanning = true;
  static const bool enablePDFGeneration = true;
  static const bool enableSync = true;
  
  // Timeouts (in seconds)
  static const int apiTimeout = 30;
  static const int imageUploadTimeout = 60;
  static const int syncTimeout = 120;
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 100; // MB
  
  // Development URLs (for testing)
  static String get apiUrl {
    if (isDevelopment) {
      return 'http://192.168.1.100:5000'; // Local development server
    }
    return apiBaseUrl;
  }
  
  // Get full API endpoint
  static String getApiEndpoint(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$apiUrl/api/$apiVersion$cleanPath';
  }
  
  // Validation Rules
  static const Map<String, dynamic> validationRules = {
    'minPasswordLength': 8,
    'maxNotesLength': 500,
    'maxDefectsLength': 1000,
    'maxLocationLength': 100,
  };
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'networkError': 'Please check your internet connection',
    'syncError': 'Failed to sync data. Will retry automatically.',
    'authError': 'Please login again',
    'validationError': 'Please check your input',
    'serverError': 'Server error. Please try again later.',
  };
  
  // Success Messages
  static const Map<String, String> successMessages = {
    'inspectionComplete': 'Inspection completed successfully',
    'syncComplete': 'All data synced successfully',
    'reportGenerated': 'Report generated successfully',
    'photoSaved': 'Photo saved successfully',
  };
}