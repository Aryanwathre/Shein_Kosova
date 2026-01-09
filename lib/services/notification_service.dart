import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shein_kosova/services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }

    // Initialize local notifications for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Create Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      await _saveTokenToBackend(newToken);
      await saveUserToFirestore(token: newToken);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['path']);
    });

    // Handle notification when app is terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['path']);
    }

    // Get and save initial token
    await refreshAndSaveToken();
  }

  Future<void> refreshAndSaveToken() async {
    try {
      String? token = await getToken();
      if (token != null) {
        debugPrint("Initial FCM Token: $token");
        await _saveTokenToBackend(token);
        await saveUserToFirestore(token: token);
      }
    } catch (e) {
      debugPrint("Error in refreshAndSaveToken: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          // Wait for APNS token if not immediately available
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _fcm.getAPNSToken();
        }
        if (apnsToken == null) return null;
      }
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> saveUserToFirestore({
    required String token,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = await ApiServiceManager().getCurrentUser();
      String? userId;

      if (userData != null && userData['id'] != null) {
        userId = userData['id'].toString();
      } else if (additionalData != null && additionalData['id'] != null) {
        userId = additionalData['id'].toString();
      }

      if (userId != null) {
        final dataToSave = {
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          if (additionalData != null) ...additionalData,
        };

        await _firestore.collection('users').doc(userId).set(
              dataToSave,
              SetOptions(merge: true),
            );
        debugPrint("User data and FCM Token saved to Firestore for user: $userId");
      }
    } catch (e) {
      debugPrint("Error saving user data to Firestore: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['path'],
    );
  }

  void _handleNotificationTap(String? path) {
    if (path != null && path.isNotEmpty) {
      debugPrint("Navigating to: $path");
      // You can implement custom navigation logic here if needed
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    bool loggedIn = await ApiServiceManager().isUserLoggedIn();
    if (loggedIn) {
      debugPrint("Saving FCM token to backend: $token");
      // TODO: Implement actual backend call if required
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
