class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final bool isBanned;
  final double rating;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.address,
    this.isBanned = false,
    this.rating = 0.0,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Pengguna',
      role: json['role'] ?? 'user',
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      phone: json['phone'],
      address: json['address'],
      isBanned: json['is_banned'] ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : _simulateRating(json['id']?.toString() ?? ''),
      isVerified: json['is_verified'] ?? _simulateVerified(json['id']?.toString() ?? ''),
    );
  }

  // Simulate reputation because backend doesn't have it yet
  static double _simulateRating(String id) {
    if (id.isEmpty) return 0.0;
    int hash = id.hashCode.abs();
    return (3.5 + (hash % 15) / 10).clamp(0.0, 5.0); // Random 3.5 to 4.9
  }

  static bool _simulateVerified(String id) {
    if (id.isEmpty) return false;
    return id.hashCode % 3 == 0; // Randomly 1/3 users are verified
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'address': address,
      'is_banned': isBanned,
      'rating': rating,
      'is_verified': isVerified,
    };
  }
}
