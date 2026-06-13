import 'dart:convert';
import '../models/user.dart';
import '../models/post.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _apiService.get('/admin/statistics', requireAuth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil statistik');
    }
  }

  Future<List<User>> getUsers() async {
    final response = await _apiService.get('/admin/users', requireAuth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> usersJson = data['data']['users'];
      return usersJson.map((json) => User.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil daftar pengguna');
    }
  }

  Future<void> toggleBanUser(String userId, bool isBanned) async {
    final response = await _apiService.patch(
      '/admin/users/$userId/ban',
      {'isBanned': isBanned},
      requireAuth: true
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengubah status pengguna');
    }
  }

  Future<List<Post>> getPosts() async {
    final response = await _apiService.get('/admin/posts', requireAuth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> postsJson = data['data']['posts'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil daftar laporan');
    }
  }

  Future<void> deletePost(String postId) async {
    final response = await _apiService.delete('/admin/posts/$postId', requireAuth: true);
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal menghapus laporan');
    }
  }
}
