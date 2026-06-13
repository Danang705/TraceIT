import 'user.dart';
import 'post.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'location'
  final String createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      chatId: json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class Chat {
  final String id;
  final String postId;
  final String responseId;
  final String user1Id;
  final String user2Id;
  final String createdAt;
  final Post? post;
  final User? partner; // Inferred as the other user in the chat
  Message? lastMessage;
  int unreadCount = 0;

  Chat({
    required this.id,
    required this.postId,
    required this.responseId,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    this.post,
    this.partner,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine who the partner is
    User? chatPartner;
    if (json['user1'] != null && json['user1']['id'] != currentUserId) {
      chatPartner = User.fromJson(json['user1']);
    } else if (json['user2'] != null && json['user2']['id'] != currentUserId) {
      chatPartner = User.fromJson(json['user2']);
    }

    // Parse last message if exists
    Message? latestMsg;
    if (json['messages'] != null && json['messages'].isNotEmpty) {
      latestMsg = Message.fromJson(json['messages'][0]);
    }

    return Chat(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? json['post']?['id']?.toString() ?? '',
      responseId: json['response_id']?.toString() ?? '',
      user1Id: json['user1_id']?.toString() ?? json['user1']?['id']?.toString() ?? '',
      user2Id: json['user2_id']?.toString() ?? json['user2']?['id']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      post: json['post'] != null ? Post.fromJson(json['post']) : null,
      partner: chatPartner,
      lastMessage: latestMsg,
    );
  }
}
