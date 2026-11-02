// lib/services/notifications_service.dart
// ============================================================
// NotificationsService — إدارة إشعارات FCM (Firebase)
// ============================================================

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_service.dart';

const String _kAndroidChannelId = 'golden_party_default';
const String _kAndroidChannelName = 'Golden Party';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// معالج الخلفية — يجب أن يكون top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '🔔 FCM background: ${message.messageId} '
    'title=${message.notification?.title}',
  );
}

class NotificationsService {
  static final SupabaseClient _client = Supabase.instance.client;

  static bool _initialized = false;
  static FirebaseMessaging? _messaging;

  static const int _maxTokenAttempts = 5;
  static const int _tokenRetryDelaySeconds = 1;

  // ============================================================
  // التهيئة
  // ============================================================

  static Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      debugPrint('🔔 Notifications disabled on Web');
      _initialized = true;
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      await _initLocalNotifications();

      _messaging = FirebaseMessaging.instance;

      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 FCM permission: ${settings.authorizationStatus}',
      );

      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        debugPrint('🔔 FCM token refreshed');
        await _saveToken(token);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint(
          '🔔 FCM foreground: ${message.notification?.title} — '
          '${message.notification?.body}',
        );
        await _showLocalNotification(message);
      });

      final token = await _messaging!.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('🔔 Current FCM token: ${token.substring(0, 12)}…');
        await _saveToken(token);
      }

      _initialized = true;
      debugPrint('✅ FCM initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization failed: $e');
      debugPrint('$stackTrace');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(settings: initSettings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kAndroidChannelId,
        _kAndroidChannelName,
        description: 'إشعارات تطبيق Golden Party',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Golden Party';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    if (body.isEmpty && (message.notification?.title == null)) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      _kAndroidChannelName,
      channelDescription: 'إشعارات تطبيق Golden Party',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  // ============================================================
  // حفظ التوكن
  // ============================================================

  static Future<void> _saveToken(String token) async {
    try {
      final identifier = await SessionService.getIdentifier();

      if (identifier == null || identifier.isEmpty) {
        debugPrint('⚠️ Cannot save FCM token: no authenticated user');
        return;
      }

      await _client.from('app_users').upsert(
        {
          'identifier': identifier,
          'fcm_token': token,
          'is_active': true,
        },
        onConflict: 'identifier',
      );

      debugPrint('✅ FCM token saved for user: $identifier');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  // ============================================================
  // تسجيل المستخدم الحالي
  // ============================================================

  static Future<void> registerCurrentUser() async {
    if (kIsWeb) return;

    if (!_initialized) {
      debugPrint(
        '⚠️ NotificationsService not initialized — skipping registration',
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        debugPrint('⚠️ Cannot register notifications: user not logged in');
        return;
      }

      debugPrint('🔔 Registering FCM for user: ${user.id}');

      String? token;
      for (int i = 0; i < _maxTokenAttempts; i++) {
        token = await _messaging?.getToken();
        if (token != null && token.isNotEmpty) break;

        debugPrint(
          '⏳ Waiting for FCM token… ${i + 1}/$_maxTokenAttempts',
        );

        if (i < _maxTokenAttempts - 1) {
          await Future.delayed(
            const Duration(seconds: _tokenRetryDelaySeconds),
          );
        }
      }

      if (token == null || token.isEmpty) {
        debugPrint('❌ FCM token was not created');
        return;
      }

      debugPrint('✅ FCM token: ${token.substring(0, 12)}…');
      await _saveToken(token);
      debugPrint('✅ Current user registered for notifications');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to register current user: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // تسجيل الخروج
  // ============================================================

  static Future<void> logout() async {
    if (kIsWeb) return;

    if (!_initialized) {
      debugPrint(
        '⚠️ NotificationsService not initialized — skipping logout',
      );
      return;
    }

    try {
      final identifier = await SessionService.getIdentifier();
      if (identifier != null && identifier.isNotEmpty) {
        await _client.from('app_users').update({
          'fcm_token': null,
        }).eq('identifier', identifier);
      }

      await _messaging?.deleteToken();
      debugPrint('✅ FCM logged out');
    } catch (e) {
      debugPrint('❌ FCM logout failed: $e');
    }
  }
}
