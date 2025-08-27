import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _authToken;
  String? _userId;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  String? get userId => _userId;
  String? get userName => _userName;

  AuthService() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(AppConstants.keyAuthToken);
    _userId = prefs.getString(AppConstants.keyUserId);
    _isAuthenticated = _authToken != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      // TODO: Implement actual API call
      // For now, simulate login
      await Future.delayed(const Duration(seconds: 1));
      
      _authToken = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
      _userId = '1';
      _userName = username;
      _isAuthenticated = true;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyAuthToken, _authToken!);
      await prefs.setString(AppConstants.keyUserId, _userId!);
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _authToken = null;
    _userId = null;
    _userName = null;
    _isAuthenticated = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyUserId);
    
    notifyListeners();
  }
}