import 'dart:convert';
import '../models/chat.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  Future<List<Chat>> getChats(String currentUserId) async {
    final response = await _apiService.get('/chats');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> chatsJson = data['data'];
      return chatsJson.map((json) => Chat.fromJson(json, currentUserId)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil daftar chat');
    }
  }

  Future<List<Message>> getMessages(String roomId, {int page = 1}) async {
    final response = await _apiService.get('/chats/$roomId/messages?page=$page');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> msgJson = data['data'];
      // The backend usually returns messages ordered by date DESC.
      // We will reverse them in the UI if needed, or keep them as is for ListView.builder(reverse: true).
      return msgJson.map((json) => Message.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil pesan');
    }
  }
}
