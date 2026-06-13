import 'user.dart';

class Post {
  final String id;
  final String type; // 'lost' or 'found'
  final String category;
  final String title;
  final String description;
  final String date;
  final double latitude;
  final double longitude;
  final String status;
  final String? imageUrl;
  final User? user;

  Post({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.imageUrl,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Determine the first image URL if images array exists
    String? firstImage;
    if (json['images'] != null && json['images'].isNotEmpty) {
      final firstElement = json['images'][0];
      if (firstElement is String) {
        firstImage = firstElement;
      } else if (firstElement is Map) {
        firstImage = firstElement['image_url'] ?? firstElement['url'];
      }
    }

    return Post(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'lost',
      category: json['category'] ?? 'Lainnya',
      title: json['title'] ?? 'Tanpa Judul',
      description: json['description'] ?? '',
      date: json['date'] ?? json['event_date'] ?? json['created_at'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? json['lat']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? json['lng']?.toString() ?? '0.0') ?? 0.0,
      status: json['status'] ?? 'active',
      imageUrl: firstImage,
      user: _parseUser(json),
    );
  }

  static User? _parseUser(Map<String, dynamic> json) {
    if (json['users'] != null) {
      return User(
        id: json['user_id']?.toString() ?? '',
        name: json['users']['name'] ?? 'Pengguna',
        email: json['users']['email'] ?? '',
        avatarUrl: json['users']['avatar_url'] ?? json['users']['avatar'],
        role: json['users']['role'] ?? 'user',
      );
    }
    if (json['user'] != null) {
      return User.fromJson(json['user']);
    }
    if (json['user_id'] != null) {
      return User(
        id: json['user_id'].toString(),
        name: 'Pengguna Rahasia',
        email: '',
        role: 'user',
      );
    }
    return null;
  }
}
