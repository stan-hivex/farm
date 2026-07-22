import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_util.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android and iOS display notification payloads automatically while the app
  // is backgrounded. Keep this handler registered for data-only messages.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Map<String, dynamic>? _pendingTapPayload;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      await _initializeLocalNotifications();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _messaging.onTokenRefresh.listen((token) async {
      await _storeToken(token);
      await registerForCurrentUser(token: token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingTapPayload = _payloadFromMessage(initialMessage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatePendingTap();
      });
    }

    await registerForCurrentUser();
  }

  static Future<void> registerForCurrentUser({String? token}) async {
    if (kIsWeb || FFAppState().accessToken.isEmpty) return;
    try {
      final resolvedToken = token ?? await _messaging.getToken();
      if (resolvedToken == null || resolvedToken.isEmpty) return;
      await _storeToken(resolvedToken);
      await ApiService.registerDeviceToken(
        token: resolvedToken,
        platform: defaultTargetPlatform.name,
      );
    } catch (e) {
      debugPrint('[NotificationService] Token registration failed: $e');
    }
  }

  static Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_device_token', token);
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _handlePayload(jsonDecode(payload) as Map<String, dynamic>);
        } catch (_) {
          _handlePayload({'type': 'general'});
        }
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'farm_notifications',
        'FARM notifications',
        description: 'FARM account and transaction notifications',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = _payloadFromMessage(message);
    FFAppState().unreadNotificationCount =
        FFAppState().unreadNotificationCount + 1;

    if (kIsWeb) return;
    final notification = message.notification;
    final title = notification?.title ?? payload['title']?.toString() ?? 'FARM';
    final body = notification?.body ?? payload['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'farm_notifications',
          'FARM notifications',
          channelDescription: 'FARM account and transaction notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(payload),
    );
  }

  static Map<String, dynamic> _payloadFromMessage(RemoteMessage message) {
    return <String, dynamic>{
      ...message.data,
      if (message.notification?.title != null)
        'title': message.notification!.title,
      if (message.notification?.body != null)
        'body': message.notification!.body,
    };
  }

  static void _handleMessageTap(RemoteMessage message) {
    _handlePayload(_payloadFromMessage(message));
  }

  static void _handlePayload(Map<String, dynamic> payload) {
    _pendingTapPayload = payload;
    _navigatePendingTap();
  }

  static void _navigatePendingTap() {
    final payload = _pendingTapPayload;
    final context = appNavigatorKey.currentContext;
    if (payload == null || context == null) return;

    final type = (payload['type'] ?? 'general').toString().toLowerCase();
    String route;
    if (type.contains('transfer')) {
      route = '/allTransactions';
    } else if (type.contains('request')) {
      route = '/incoming-requests';
    } else if (type.contains('deposit')) {
      route = '/depositpage';
    } else if (type.contains('withdraw')) {
      route = '/withdrawpage';
    } else if (type.contains('merchant')) {
      route = '/merchantSales';
    } else {
      route = '/user-notifications';
    }

    context.go(route);
    _pendingTapPayload = null;
  }
}