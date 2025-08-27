// lib/config/app_config.dart
class AppConfig {
  // API Configuration - Updated for Flask dev server
  static const String apiBaseUrl = 'https://firealarmsupporttools.com'; // Production URL
  static const String apiVersion = 'v1';
  
  // Development/Production flags
  static const bool isDevelopment = true; // Set to false for production
  
  // Flask Dev Server Configuration
  static const String flaskDevServerIp = '192.168.1.141';
  static const int flaskDevServerPort = 5000;
  
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
  static const String companyName = '247';
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
  
  // Get the correct API URL based on environment
  static String get apiUrl {
    if (isDevelopment) {
      // Use Flask dev server with /inspection-api/ prefix
      return 'http://$flaskDevServerIp:$flaskDevServerPort/inspection-api';
    }
    // Production URL would be something like:
    // return 'https://firealarmsupporttools.com/api';
    return apiBaseUrl;
  }
  
  // Get full API endpoint - UPDATED for Flask API structure
  static String getApiEndpoint(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    // In development, apiUrl already includes /inspection-api
    // so we don't need to add /api/v1 prefix
    if (isDevelopment) {
      return '$apiUrl$cleanPath';
    }
    // For production, you might need different path structure
    return '$apiUrl/api/$apiVersion$cleanPath';
  }
  
  // Flask API Endpoints (for reference)
  static const String authLoginEndpoint = '/auth/login';
  static const String authRefreshEndpoint = '/auth/refresh';
  static const String authLogoutEndpoint = '/auth/logout';
  static const String buildingsEndpoint = '/buildings';
  static const String customersEndpoint = '/customers';
  static const String systemsEndpoint = '/systems';
  static const String devicesEndpoint = '/devices';
  static const String inspectionsEndpoint = '/inspections';
  static const String batteryTestsEndpoint = '/battery-tests';
  static const String componentTestsEndpoint = '/component-tests';
  static const String ticketsEndpoint = '/tickets';
  static const String syncCheckEndpoint = '/sync/check';
  static const String syncBatchEndpoint = '/sync/batch';
  
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