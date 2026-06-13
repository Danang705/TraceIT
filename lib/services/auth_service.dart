import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(
      '/auth/login', 
      {'email': email, 'password': password},
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['data']; // Returns { user, accessToken, refreshToken }
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String phone) async {
    final response = await _apiService.post(
      '/auth/register', 
      {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone
      },
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

  Future<User> getMe() async {
    final response = await _apiService.get('/auth/me');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return User.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch user profile');
    }
  }

  Future<User> getUserProfile(String userId) async {
    final response = await _apiService.get('/users/$userId');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return User.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch user profile');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await _apiService.post(
      '/auth/forgot-password', 
      {'email': email},
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<String> verifyOtp(String email, String otpCode) async {
    final response = await _apiService.post(
      '/auth/verify-otp', 
      {'email': email, 'otpCode': otpCode},
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['data']['resetToken'];
    } else {
      throw Exception(data['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    final response = await _apiService.post(
      '/auth/reset-password', 
      {'resetToken': resetToken, 'newPassword': newPassword},
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to reset password');
    }
  }

  Future<String> uploadAvatar(XFile file) async {
    final response = await _apiService.uploadFile('/upload', file, folder: 'avatars');
    
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    
    if (response.statusCode == 200) {
      return data['data']['url'];
    } else {
      throw Exception(data['message'] ?? 'Gagal mengunggah foto profil');
    }
  }

  Future<void> logout(String refreshToken) async {
    final response = await _apiService.post(
      '/auth/logout', 
      {'refreshToken': refreshToken},
      requireAuth: true
    );
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Logout failed on server');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _apiService.post(
      '/auth/refresh-token', 
      {'refreshToken': refreshToken},
      requireAuth: false
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['data']; // Returns { accessToken, refreshToken }
    } else {
      throw Exception(data['message'] ?? 'Failed to refresh token');
    }
  }

  Future<User> updateProfile({String? avatar, String? phone, String? address}) async {
    final response = await _apiService.put(
      '/users/profile', 
      {'avatar': avatar, 'phone': phone, 'address': address},
      requireAuth: true
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return User.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Gagal memperbarui profil');
    }
  }
}
