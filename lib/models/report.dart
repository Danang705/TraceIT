class Report {
  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
  final String reporterName;
  final String reporterEmail;
  final String postTitle;
  final String postOwnerId;

  Report({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
    required this.reporterName,
    required this.reporterEmail,
    required this.postTitle,
    required this.postOwnerId,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final reporterJson = json['reporter'] ?? {};
    final postJson = json['post'] ?? {};
    return Report(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      reporterName: reporterJson['name']?.toString() ?? 'Pengguna',
      reporterEmail: reporterJson['email']?.toString() ?? '',
      postTitle: postJson['title']?.toString() ?? 'Postingan tidak dikenal',
      postOwnerId: postJson['user_id']?.toString() ?? '',
    );
  }
}
