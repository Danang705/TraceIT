import 'dart:convert';
import '../models/comment.dart';
import 'api_service.dart';

class CommentService {
  final ApiService _apiService = ApiService();

  Future<List<Comment>> getComments(String postId) async {
    final response = await _apiService.get('/comments/post/$postId', requireAuth: false);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> commentsJson = data['data'];
      return commentsJson.map((json) => Comment.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil komentar');
    }
  }

  Future<Comment> addComment(String postId, String content) async {
    final response = await _apiService.post('/comments', {
      'postId': postId,
      'content': content,
    }, requireAuth: true);
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Comment.fromJson(data['data']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengirim komentar');
    }
  }

  Future<void> deleteComment(String commentId) async {
    final response = await _apiService.delete('/comments/$commentId', requireAuth: true);
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal menghapus komentar');
    }
  }
}
