import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];

  /// All notifications (chat + claim)
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  /// Only non-chat notifications (for the notification page)
  List<NotificationItem> get claimNotifications =>
      List.unmodifiable(_notifications.where((n) => !n.isChat).toList());

  /// Badge count = only non-chat notifications
  int get unreadCount => _notifications.where((n) => !n.isChat).length;

  void add(NotificationItem item) {
    _notifications.insert(0, item); // newest first
    notifyListeners();
  }

  void removeById(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    // Only clear non-chat notifications
    _notifications.removeWhere((n) => !n.isChat);
    notifyListeners();
  }
}
