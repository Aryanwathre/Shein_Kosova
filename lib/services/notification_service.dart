import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Callback for handling notification navigation
  static void Function(String? path)? onNotificationTap;

  Future<void> init() async {
    // Ensure Firebase is initialized
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase not initialized. Skipping notification setup.');
      return;
    }

    // Skip notification setup on web - web uses browser push notifications
    if (kIsWeb) {
      debugPrint('Running on web platform. Browser push notifications can be set up separately.');
      return;
    }

    // Request permissions (mobile only)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User denied notification permission');
    }

    // Initialize local notifications for Android/iOS
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    // Create Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Request iOS notification permissions
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    // Set up notification handlers BEFORE calling getInitialMessage
    _setupNotificationHandlers();

    // Handle notification when app is terminated (killed state)
    // This must be called after setting up handlers
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from killed state with notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage.data['path']);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      await _saveTokenToBackend(newToken);
      await saveUserToFirestore(token: newToken);
    });

    // Get and save initial token
    await refreshAndSaveToken();
  }

  void _setupNotificationHandlers() {
    // Skip handlers on web
    if (kIsWeb) return;

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages (app open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Handling a foreground message: ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background state with notification: ${message.messageId}');
      _handleNotificationTap(message.data['path']);
    });
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
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          // Wait for APNS token if not immediately available
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _fcm.getAPNSToken();
          debugPrint("APNS Token: $apnsToken");
        }
        if (apnsToken == null) {
          debugPrint("Warning: APNS token is null on iOS");
          return null;
        }
      }
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      return token;
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
          'platform': kIsWeb ? 'Web' : (Platform.isIOS ? 'iOS' : 'Android'),
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
    if (kIsWeb) return;
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosNotificationDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: message.data['path'] ?? '',
      );
    } catch (e) {
      debugPrint("Error showing local notification: $e");
    }
  }

  void _handleNotificationTap(String? path) {
    if (path != null && path.isNotEmpty) {
      debugPrint("Notification tapped, navigating to: $path");
      // Call the registered callback if available
      if (onNotificationTap != null) {
        onNotificationTap!(path);
      }
    }
  }

  // Callback for background notification responses
  @pragma('vm:entry-point')
  static Future<void> _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    debugPrint('Background notification response: payload=${notificationResponse.payload}');
    if (onNotificationTap != null) {
      onNotificationTap!(notificationResponse.payload);
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

  // Handle data-only messages in background
  if (message.data.isNotEmpty) {
    debugPrint('Message data: ${message.data}');
  }

  if (message.notification != null) {
    debugPrint('Message notification: title=${message.notification?.title}, body=${message.notification?.body}');
  }
}
