// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  late Dio _dio;
  String? _authToken;
  
  ApiService._init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl, // This now points to Flask dev server
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Token expired, need to re-authenticate
          _handleAuthError();
        }
        handler.next(error);
      },
    ));
  }
  
  /// Check if device has internet connection
  Future<bool> hasConnection() async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Also try to ping the server
      try {
        await _dio.get('/health', 
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          )
        );
        return true;
      } catch (e) {
        // If server is not reachable
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Set authentication token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    if (token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }
  
  /// Get stored auth token
  Future<String?> getStoredAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }
  
  /// Clear authentication
  Future<void> clearAuth() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  /// Handle authentication errors
  void _handleAuthError() {
    // Clear auth and notify app to redirect to login
    clearAuth();
    // You might want to use an event bus or state management
    // to notify the app about auth failure
  }
  
  /// Login - CORRECTED FOR FLASK API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Flask API uses email, not username
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Flask returns access_token, not token
      if (response.data['access_token'] != null) {
        await setAuthToken(response.data['access_token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await clearAuth();
    }
  }
  
  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Upload file with multipart
  Future<Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData();
      
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(file.path, filename: fileName),
      ));
      
      if (additionalData != null) {
        formData.fields.addAll(
          additionalData.entries.map((e) => MapEntry(e.key, e.value.toString())),
        );
      }
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Upload multiple files
  Future<Response> uploadMultipleFiles(
    String path,
    List<File> files, {
    String fieldName = 'files',
    Map<String, dynamic>? additionalData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      
      for (var file in files) {
        final fileName = file.path.split('/').last;
        formData.files.add(MapEntry(
          fieldName,
          await MultipartFile.fromFile(file.path, filename: fileName),
        ));
      }
      
      if (additionalData != null) {
        formData.fields.addAll(
          additionalData.entries.map((e) => MapEntry(e.key, e.value.toString())),
        );
      }
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ===== INSPECTION-SPECIFIC METHODS =====
  
  /// Create inspection
  Future<Map<String, dynamic>> createInspection(Map<String, dynamic> data) async {
    try {
      final response = await post('/inspections', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Create battery test
  Future<Map<String, dynamic>> createBatteryTest(int inspectionId, Map<String, dynamic> data) async {
    try {
      final response = await post('/inspections/$inspectionId/batteries', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Create component test
  Future<Map<String, dynamic>> createComponentTest(int inspectionId, Map<String, dynamic> data) async {
    try {
      final response = await post('/inspections/$inspectionId/components', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Create service ticket
  Future<Map<String, dynamic>> createServiceTicket(Map<String, dynamic> data) async {
    try {
      final response = await post('/tickets', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Get buildings
  Future<List<dynamic>> getBuildings() async {
    try {
      final response = await get('/buildings');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Get customers
  Future<List<dynamic>> getCustomers() async {
    try {
      final response = await get('/customers');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Get properties/systems
  Future<List<dynamic>> getSystems() async {
    try {
      final response = await get('/systems');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Get devices
  Future<List<dynamic>> getDevices({int? propertyId}) async {
    try {
      final queryParams = propertyId != null ? {'property_id': propertyId} : null;
      final response = await get('/devices', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Handle Dio errors
  String _handleDioError(DioException error) {
    String errorMessage = 'An error occurred';
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        
        if (responseData is Map && responseData['error'] != null) {
          errorMessage = responseData['error'];
        } else if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else {
          switch (statusCode) {
            case 400:
              errorMessage = 'Bad request';
              break;
            case 401:
              errorMessage = 'Authentication failed';
              break;
            case 403:
              errorMessage = 'Access forbidden';
              break;
            case 404:
              errorMessage = 'Resource not found';
              break;
            case 500:
              errorMessage = 'Server error';
              break;
            default:
              errorMessage = 'Error: $statusCode';
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = 'Certificate verification failed';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection';
        break;
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          errorMessage = 'No internet connection';
        } else {
          errorMessage = error.message ?? 'Unknown error occurred';
        }
    }
    
    return errorMessage;
  }
}