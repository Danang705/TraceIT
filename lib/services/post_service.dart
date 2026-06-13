import 'dart:convert';
import '../models/post.dart';
import 'api_service.dart';
import 'package:image_picker/image_picker.dart';

class PostService {
  final ApiService _apiService = ApiService();

  Future<List<Post>> getPosts({
    String? type,
    double? radius,
    double? lat,
    double? lng,
    String? search,
    String? category,
  }) async {
    List<String> queryParams = [];
    if (type != null && type != 'all') queryParams.add('type=$type');
    if (radius != null) queryParams.add('radius=$radius');
    if (lat != null) queryParams.add('lat=$lat');
    if (lng != null) queryParams.add('lng=$lng');
    if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
    if (category != null && category.isNotEmpty) queryParams.add('category=${Uri.encodeComponent(category)}');

    String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    
    final response = await _apiService.get('/posts$queryString', requireAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> postsJson = data['data'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil data postingan');
    }
  }

  Future<Post> getPostById(String postId) async {
    final response = await _apiService.get('/posts/$postId', requireAuth: false);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Post.fromJson(data['data']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil detail postingan');
    }
  }

  Future<String> uploadImage(XFile file) async {
    final response = await _apiService.uploadFile('/upload', file, folder: 'posts');
    
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);
    
    if (response.statusCode == 200) {
      return data['data']['url'];
    } else {
      throw Exception(data['message'] ?? 'Gagal mengunggah gambar');
    }
  }

  Future<void> createPost(Map<String, dynamic> postData) async {
    final response = await _apiService.post('/posts', postData, requireAuth: true);
    
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal membuat laporan');
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> postData) async {
    final response = await _apiService.put('/posts/$postId', postData, requireAuth: true);
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal memperbarui laporan');
    }
  }

  Future<void> deletePost(String postId) async {
    final response = await _apiService.delete('/posts/$postId', requireAuth: true);
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal menghapus laporan');
    }
  }

  Future<List<Post>> getMapPosts(double lat, double lng, int radiusKm) async {
    final response = await _apiService.get('/posts/maps?lat=$lat&lng=$lng&radius=$radiusKm');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> postsJson = data['data'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil data peta');
    }
  }

  Future<void> updatePostStatus(String postId, String status) async {
    final response = await _apiService.patch(
      '/posts/$postId/status', 
      {'status': status}, 
      requireAuth: true
    );
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal memperbarui status laporan');
    }
  }
}
