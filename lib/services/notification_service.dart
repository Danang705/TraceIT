import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/chat.dart';
import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import '../screens/chat/chat_room_screen.dart';
import '../main.dart'; // for navigatorKey
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] Got message: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  static const String _channelId = 'traceit_notifications';
  static const String _channelName = 'TraceIT Notifications';
  static const String _channelDesc = 'Notifikasi untuk TraceIT - Lost & Found App';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      print('[FCM] Initializing NotificationService...');
      _fcm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _requestPermission();
      await _initLocalNotifications();
      await _registerTokenToServer();

      _fcm?.onTokenRefresh.listen((newToken) async {
        await _sendTokenToServer(newToken);
      });

      // Foreground: app is open and visible
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background: user tapped notification while app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[FCM] onMessageOpenedApp: ${message.data}');
        print('[FCM] onMessageOpenedApp notification: ${message.notification?.title}');
        _saveAndNavigate(message);
      });

      // Terminated: user tapped notification while app was closed
      final initialMessage = await _fcm?.getInitialMessage();
      if (initialMessage != null) {
        print('[FCM] Initial message: ${initialMessage.data}');
        print('[FCM] Initial notification: ${initialMessage.notification?.title}');
        // Delay to let the app fully build before navigating
        Future.delayed(const Duration(seconds: 2), () {
          _saveAndNavigate(initialMessage);
        });
      }

      print('[FCM] NotificationService initialized successfully');
    } catch (e) {
      print('[FCM] Error during initialization: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    await _fcm?.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initLocalNotifications() async {
    if (kIsWeb) return;
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
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _fcm?.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Called when a LOCAL notification (shown while foreground) is tapped
  void _onLocalNotificationTapped(NotificationResponse response) {
    print('[FCM] Local notification tapped, payload: ${response.payload}');
    if (response.payload == null || response.payload!.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      _navigateFromPayload(data);
    } catch (e) {
      print('[FCM] Error parsing local notification payload: $e');
    }
  }

  Future<void> _registerTokenToServer() async {
    if (kIsWeb) return;
    final token = await _fcm?.getToken();
    if (token == null) return;
    print('[FCM] Token: $token');
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    if (kIsWeb) return;
    try {
      await _apiService.post(
        '/notifications/register-token',
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
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcm_token');
      if (token != null) {
        await _apiService.delete(
          '/notifications/unregister-token',
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

  // ──────────────────────────────────────────────
  //  DETECTION: is this a chat notification?
  // ──────────────────────────────────────────────

  /// Detect if a notification is about chat/messaging
  /// Uses BOTH data fields AND notification title/body content
  bool _isChatNotification(Map<String, dynamic> data, {String? title, String? body}) {
    // 1. Check data 'type' field explicitly
    final type = data['type']?.toString().toLowerCase() ?? '';
    if (type == 'chat' || type == 'message' || type == 'new_message') return true;

    // 2. Check notification title/body for chat-related keywords
    final t = (title ?? '').toLowerCase();
    final b = (body ?? '').toLowerCase();
    if (t.contains('pesan baru') || t.contains('new message') ||
        t.contains('mengirim pesan') || t.contains('chat')) return true;

    // 3. If type is explicitly NOT chat (e.g., claim, response, etc.), it's not chat
    if (type.isNotEmpty && type != 'chat' && type != 'message') return false;

    // 4. Default: if no type field exists at all, it's NOT a chat notification
    return false;
  }

  /// Extract chat room ID from payload data
  String? _extractRoomId(Map<String, dynamic> data) {
    final dynamic roomId = data['roomId'] ??
        data['room_id'] ??
        data['chat_id'] ??
        data['chatId'];
    return roomId?.toString();
  }

  // ──────────────────────────────────────────────
  //  FOREGROUND: app is open and visible
  // ──────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    // Log FULL payload for debugging
    print('[FCM] ===== FOREGROUND MESSAGE =====');
    print('[FCM] Title: ${notification.title}');
    print('[FCM] Body: ${notification.body}');
    print('[FCM] Data: ${message.data}');
    print('[FCM] ================================');

    final isChat = _isChatNotification(
      message.data,
      title: notification.title,
      body: notification.body,
    );

    print('[FCM] isChat: $isChat');

    // Save to provider (ALL notifications get saved, but flagged as chat or not)
    _saveToProvider(
      title: notification.title ?? 'Notifikasi',
      body: notification.body ?? '',
      data: message.data,
      isChat: isChat,
    );

    // Show local notification for ALL types
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

  // ──────────────────────────────────────────────
  //  BACKGROUND/TERMINATED: user tapped notification
  // ──────────────────────────────────────────────

  /// Save notification to provider AND navigate if chat
  void _saveAndNavigate(RemoteMessage message) {
    final notification = message.notification;
    final isChat = _isChatNotification(
      message.data,
      title: notification?.title,
      body: notification?.body,
    );

    // Save to provider
    _saveToProvider(
      title: notification?.title ?? 'Notifikasi',
      body: notification?.body ?? '',
      data: message.data,
      isChat: isChat,
    );

    // Navigate
    _navigateFromPayload(message.data);
  }

  // ──────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────

  void _saveToProvider({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required bool isChat,
  }) {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final notifProvider = Provider.of<NotificationProvider>(ctx, listen: false);
        notifProvider.add(NotificationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          body: body,
          payload: data,
          isChat: isChat,
        ));
        print('[FCM] Saved to provider (isChat=$isChat): $title');
      } else {
        print('[FCM] Context is null, could not save to provider');
      }
    } catch (e) {
      print('[FCM] Error saving to provider: $e');
    }
  }

  /// Navigate to chat room if payload contains a room ID
  void _navigateFromPayload(Map<String, dynamic> data) {
    print('[FCM] Attempting navigation from payload: $data');

    final roomId = _extractRoomId(data);
    if (roomId != null && roomId.isNotEmpty) {
      print('[FCM] Found roomId: $roomId → navigating to ChatRoom');
      Future.delayed(const Duration(milliseconds: 500), () {
        final state = navigatorKey.currentState;
        if (state != null) {
          final chat = Chat.fromId(roomId);
          state.push(MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chat: chat),
          ));
        } else {
          print('[FCM] Navigator state is null');
        }
      });
    } else {
      print('[FCM] No roomId in payload, no chat navigation');
    }
  }
}
