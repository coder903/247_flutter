// ============================================
// FIX 1: Update auth_service.dart
// ============================================
// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';  // ADD THIS IMPORT
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Make AuthService extend ChangeNotifier
class AuthService extends ChangeNotifier {  // ADD extends ChangeNotifier
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _authToken;
  String? _refreshToken;
  Map<String, dynamic>? _userInfo;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  Map<String, dynamic>? get userInfo => _userInfo;
  
  // ADD THESE GETTERS
  String? get userName => _userInfo?['name'];
  String? get userId => _userInfo?['id']?.toString();
  String? get userEmail => _userInfo?['email'];
  String? get userRole => _userInfo?['role'];

  // Keep the login method returning bool as your code expects
  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiService.instance.login(email, password);
      
      if (response != null && response['access_token'] != null) {
        // Store tokens
        _authToken = response['access_token'];
        _refreshToken = response['refresh_token'];
        _userInfo = response['user'];
        _isAuthenticated = true;
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        await prefs.setString('refresh_token', _refreshToken ?? '');
        await prefs.setString('user_id', _userInfo?['id']?.toString() ?? '');
        await prefs.setString('user_email', _userInfo?['email'] ?? '');
        await prefs.setString('user_name', _userInfo?['name'] ?? '');
        await prefs.setString('user_role', _userInfo?['role'] ?? '');
        
        // Set token in API service
        await ApiService.instance.setAuthToken(_authToken!);
        
        notifyListeners();  // ADD THIS
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  Future<void> loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');
    
    _isAuthenticated = _authToken?.isNotEmpty ?? false;
    
    if (_authToken?.isNotEmpty ?? false) {
      await ApiService.instance.setAuthToken(_authToken!);
      _userInfo = {
        'id': prefs.getString('user_id') ?? '',
        'email': prefs.getString('user_email') ?? '',
        'name': prefs.getString('user_name') ?? '',
        'role': prefs.getString('user_role') ?? '',
      };
    }
    notifyListeners();  // ADD THIS
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    _authToken = null;
    _refreshToken = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    ApiService.instance.setAuthToken(''); // Changed from clearAuthToken
    notifyListeners();  // ADD THIS
  }
}

