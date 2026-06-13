import 'user.dart';

class Claim {
  final String id;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? proofImage;
  final String createdAt;
  final User? user;

  Claim({
    required this.id,
    required this.message,
    required this.status,
    this.proofImage,
    required this.createdAt,
    this.user,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'],
      message: json['message'],
      status: json['status'],
      proofImage: json['proof_image_url'] ?? json['proof_image'],
      createdAt: json['created_at'],
      user: json['users'] != null 
          ? User(
              id: json['user_id']?.toString() ?? json['users']['id']?.toString() ?? '',
              name: json['users']['name'] ?? 'Pengguna',
              email: '',
              role: 'user',
              avatarUrl: json['users']['avatar_url']
            )
          : (json['user'] != null 
              ? User.fromJson(json['user']) 
              : (json['user_id'] != null 
                  ? User(id: json['user_id'].toString(), name: 'Pengguna', email: '', role: 'user') 
                  : null)),
    );
  }
}
