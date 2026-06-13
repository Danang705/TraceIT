import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] Got message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  static const String _channelId = 'traceit_notifications';
  static const String _channelName = 'TraceIT Notifications';
  static const String _channelDesc = 'Notifikasi untuk TraceIT - Lost & Found App';

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _initLocalNotifications();
    await _registerTokenToServer();

    _fcm.onTokenRefresh.listen((newToken) async {
      await _sendTokenToServer(newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);

    print('[FCM] NotificationService initialized successfully');
  }

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _registerTokenToServer() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    print('[FCM] Token: $token');
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _apiService.post(
        '/api/notifications/register-token',
        {'token': token, 'deviceType': 'android'},
        requireAuth: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('[FCM] Token registered to server');
    } catch (e) {
      print('[FCM] Failed to register token: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        await _apiService.delete(
          '/api/notifications/unregister-token',
          body: {'token': token},
          requireAuth: true,
        );
        await prefs.remove('fcm_token');
        print('[FCM] Token unregistered');
      }
    } catch (e) {
      print('[FCM] Failed to unregister token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('[FCM] Notification tapped: ${message.data}');
    // Navigation can be integrated here if needed in the future
  }
}
