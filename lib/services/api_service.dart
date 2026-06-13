import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(Constants.tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(Constants.refreshTokenKey);
    if (refreshToken == null) return false;

    final url = Uri.parse('${Constants.baseUrl}/auth/refresh-token');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['data']['accessToken'];
        final newRefreshToken = data['data']['refreshToken'];
        
        await prefs.setString(Constants.tokenKey, newAccessToken);
        if (newRefreshToken != null) {
          await prefs.setString(Constants.refreshTokenKey, newRefreshToken);
        }
        return true;
      }
    } catch (_) {
      // Ignored, fallback to normal error handling
    }
    return false;
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    
    String errorMessage = 'Terjadi kesalahan pada server (${response.statusCode})';
    try {
      final data = jsonDecode(response.body);
      if (data['message'] != null) {
        errorMessage = data['message'];
      } else if (data['error'] != null) {
        errorMessage = data['error'];
      }
    } catch (_) {
      if (response.statusCode == 401) errorMessage = 'Sesi Anda telah habis. Silakan login kembali.';
      else if (response.statusCode == 403) errorMessage = 'Akses ditolak.';
      else if (response.statusCode == 404) errorMessage = 'Data tidak ditemukan.';
      else if (response.statusCode >= 500) errorMessage = 'Server sedang gangguan. Coba lagi nanti.';
    }
    throw Exception(errorMessage);
  }

  void _handleStreamedResponse(http.StreamedResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Gagal mengunggah file (${response.statusCode})');
  }

  Future<http.Response> _requestWithRetry(Future<http.Response> Function() requestFunc, bool requireAuth) async {
    try {
      http.Response response = await requestFunc();
      
      if (requireAuth && response.statusCode == 401) {
        final bool refreshed = await _refreshToken();
        if (refreshed) {
          response = await requestFunc();
        }
      }
      
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Koneksi timeout. Server mungkin sedang sibuk.');
    } on SocketException {
      throw Exception('Koneksi gagal. Periksa jaringan Anda.');
    }
  }

  Future<http.StreamedResponse> _requestStreamWithRetry(Future<http.StreamedResponse> Function() requestFunc, bool requireAuth) async {
    try {
      http.StreamedResponse response = await requestFunc();
      
      if (requireAuth && response.statusCode == 401) {
        final bool refreshed = await _refreshToken();
        if (refreshed) {
          response = await requestFunc();
        }
      }
      
      _handleStreamedResponse(response);
      return response;
    } on TimeoutException {
      throw Exception('Koneksi timeout. Server mungkin sedang sibuk.');
    } on SocketException {
      throw Exception('Koneksi gagal. Periksa jaringan Anda.');
    }
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    return _requestWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      return await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
    }, requireAuth);
  }

  Future<http.Response> post(String endpoint, dynamic body, {bool requireAuth = true}) async {
    return _requestWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      return await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 30));
    }, requireAuth);
  }

  Future<http.Response> put(String endpoint, dynamic body, {bool requireAuth = true}) async {
    return _requestWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      return await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    }, requireAuth);
  }

  Future<http.Response> patch(String endpoint, dynamic body, {bool requireAuth = true}) async {
    return _requestWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      return await http.patch(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 15));
    }, requireAuth);
  }

  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    return _requestWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      final headers = await _getHeaders(requireAuth: requireAuth);
      return await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
    }, requireAuth);
  }

  Future<http.StreamedResponse> uploadFile(String endpoint, XFile file, {bool requireAuth = true, String folder = 'misc'}) async {
    return _requestStreamWithRetry(() async {
      final url = Uri.parse('${Constants.baseUrl}$endpoint');
      var request = http.MultipartRequest('POST', url);
      
      final headers = await _getHeaders(requireAuth: requireAuth);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.fields['folder'] = folder;
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      return await request.send();
    }, requireAuth);
  }
}
