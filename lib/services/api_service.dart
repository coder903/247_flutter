// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  late Dio _dio;
  String? _authToken;
  
  ApiService._init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
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
  
  /// Set authentication token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
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
  
  /// Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      if (response.data['token'] != null) {
        await setAuthToken(response.data['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
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
      
      for (final file in files) {
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
  
  /// Download file
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
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
        
        if (responseData is Map && responseData['message'] != null) {
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
  
  /// Check connectivity
  Future<bool> checkConnectivity() async {
    try {
      final response = await _dio.get('/api/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}