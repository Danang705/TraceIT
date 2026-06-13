class NotificationItem {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;
  final bool isChat; // true = chat notification, false = claim/other

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.isChat = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
