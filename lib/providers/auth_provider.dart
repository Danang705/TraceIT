import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(Constants.tokenKey);
    final userData = prefs.getString(Constants.userKey);
    
    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));
    }
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(Constants.tokenKey);
    final userJsonStr = prefs.getString(Constants.userKey);
    
    if (_token != null && userJsonStr != null) {
      try {
        _user = User.fromJson(jsonDecode(userJsonStr));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        _token = null;
        _user = null;
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(User updatedUser) async {
    // Preserve role from current user if the updated data defaults to 'user'
    // This prevents admin users from losing their role when updating profile
    if (_user != null && updatedUser.role == 'user' && _user!.role == 'admin') {
      _user = User(
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
        role: _user!.role,
        avatarUrl: updatedUser.avatarUrl,
        phone: updatedUser.phone,
        address: updatedUser.address,
        isBanned: updatedUser.isBanned,
        rating: updatedUser.rating,
        isVerified: updatedUser.isVerified,
      );
    } else {
      _user = updatedUser;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.userKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _authService.login(email, password);
      
      _token = data['accessToken'];
      _user = User.fromJson(data['user']);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(Constants.tokenKey, _token!);
      await prefs.setString(Constants.refreshTokenKey, data['refreshToken']);
      await prefs.setString(Constants.userKey, jsonEncode(_user!.toJson()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.register(name, email, password, phone);
      
      // Auto login after successful registration to get tokens
      return await login(email, password);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(Constants.refreshTokenKey);
    
    if (refreshToken != null) {
      try {
        await _authService.logout(refreshToken);
      } catch (e) {
        debugPrint('Backend logout failed: $e');
      }
    }

    _token = null;
    _user = null;
    
    await prefs.remove(Constants.tokenKey);
    await prefs.remove(Constants.refreshTokenKey);
    await prefs.remove(Constants.userKey);
    
    notifyListeners();
  }
}
