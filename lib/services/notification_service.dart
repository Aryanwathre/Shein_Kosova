import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shein_kosova/services/api_service.dart';
import 'dart:io' show Platform;

// Combined Firebase Messaging and Local Notifications Services

class LocalNotificationsService {
  // Private constructor for singleton pattern
  LocalNotificationsService._internal();

  // Singleton instance
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();

  // Factory constructor to return singleton instance
  factory LocalNotificationsService.instance() => _instance;

  // Main plugin instance for handling notifications
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Android-specific initialization settings using app launcher icon
  final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS-specific initialization settings with permission requests
  final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Android notification channel configuration
  // Using 'high_importance_channel' as specified in AndroidManifest.xml
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // Flag to track initialization status
  bool _isFlutterLocalNotificationInitialized = false;

  // Counter for generating unique notification IDs
  int _notificationIdCounter = 0;

  /// Initializes the local notifications plugin for Android and iOS.
  Future<void> init() async {
    // Check if already initialized to prevent redundant setup
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }

    // Create plugin instance
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Combine platform-specific settings
    final initializationSettings = InitializationSettings(
      android: _androidInitializationSettings,
      iOS: _iosInitializationSettings,
    );

    // Initialize plugin with settings and callback for notification taps
    await _flutterLocalNotificationsPlugin.initialize(
      settings:
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap in foreground
        debugPrint('Foreground notification has been tapped: ${response.payload}');
        NotificationService().handleNotificationTap(response.payload);
      },
    );

    // Create Android notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Mark initialization as complete
    _isFlutterLocalNotificationInitialized = true;
  }

  /// Show a local notification with the given title, body, and payload.
  Future<void> showNotification(
    String? title,
    String? body,
    String? payload,
  ) async {
    // Android-specific notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    // iOS-specific notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine platform-specific details
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Display the notification
    await _flutterLocalNotificationsPlugin.show(
      id:
      _notificationIdCounter++,
      title:
      title,
      body:
      body,
      notificationDetails:
      notificationDetails,
      payload: payload,
    );
  }
}

class FirebaseMessagingService {
  // Private constructor for singleton pattern
  FirebaseMessagingService._internal();

  // Singleton instance
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();

  // Factory constructor to provide singleton instance
  factory FirebaseMessagingService.instance() => _instance;

  // Reference to local notifications service for displaying notifications
  LocalNotificationsService? _localNotificationsService;

  /// Initialize Firebase Messaging and sets up all message listeners
  Future<void> init({required LocalNotificationsService localNotificationsService}) async {
    // Skip setup on web as browser push notifications are different
    if (kIsWeb) {
      debugPrint('FCM skipping setup on web');
      return;
    }

    // Init local notifications service
    _localNotificationsService = localNotificationsService;

    // Request user permission for notifications
    await _requestPermission();

    // Handle FCM token
    await _handlePushNotificationsToken();

    // Register handler for background messages (app terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for messages when the app is in foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Listen for notification taps when the app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Check for initial message that opened the app from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
  }

  /// Retrieves and manages the FCM token for push notifications
  Future<void> _handlePushNotificationsToken() async {
    // Get the FCM token for the device
    final token = await getToken();
    debugPrint('Push notifications token: $token');

    // Listen for token refresh events
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      debugPrint('FCM token refreshed: $fcmToken');
      _saveTokenToBackend(fcmToken);
    }).onError((error) {
      // Handle errors during token refresh
      debugPrint('Error refreshing FCM token: $error');
    });
  }

  /// Gets the current FCM token, handling APNS for iOS
  Future<String?> getToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        print('apnsToken loli');
        print(apnsToken);
        if (apnsToken == null) {
          // Wait for APNS token if not immediately available
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();

          debugPrint("APNS token retrieved after delay: $apnsToken");
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Requests notification permission from the user
  Future<void> _requestPermission() async {
    // Request permission for alerts, badges, and sounds
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Log the user's permission decision
    debugPrint('User granted permission: ${result.authorizationStatus}');
  }

  /// Handles messages received while the app is in the foreground
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.data}');
    final notificationData = message.notification;
    if (notificationData != null) {
      // Display a local notification using the service
      _localNotificationsService?.showNotification(
          notificationData.title, 
          notificationData.body, 
          message.data['path'] ?? message.data.toString()
      );
    }
  }

  /// Handles notification taps when app is opened from the background or terminated state
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification caused the app to open: ${message.data}');
    NotificationService().handleNotificationTap(message.data['path']);
  }

  /// Sends the FCM token to the backend if the user is logged in
  Future<void> _saveTokenToBackend(String token) async {
    try {
      bool loggedIn = await ApiServiceManager().isUserLoggedIn();
      if (loggedIn) {
        debugPrint("Saving FCM token to backend: $token");
        // TODO: If your API supports updating FCM token, call it here
      }
    } catch (e) {
      debugPrint("Error saving token to backend: $e");
    }
  }
}

/// Background message handler (must be top-level function or static)
/// Handles messages when the app is fully terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.data}');
}

/// Compatibility wrapper for existing code using NotificationService
class NotificationService {
  // Private constructor for singleton pattern
  NotificationService._internal();

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  // Factory constructor to provide singleton instance
  factory NotificationService() => _instance;

  final _firebaseService = FirebaseMessagingService.instance();
  final _localService = LocalNotificationsService.instance();

  // Callback for handling notification navigation
  static void Function(String? path)? onNotificationTap;

  /// Initialize all notification services
  Future<void> init() async {
    if (kIsWeb) return;
    
    await _localService.init();
    await _firebaseService.init(localNotificationsService: _localService);
  }

  /// Retrieves the current FCM token
  Future<String?> getToken() => _firebaseService.getToken();

  /// Refreshes and saves the token to the backend if possible
  Future<void> refreshAndSaveToken() async {
    final token = await getToken();
    if (token != null) {
      await _firebaseService._saveTokenToBackend(token);
    }
  }

  /// Handles notification taps by triggering the registered callback
  void handleNotificationTap(String? path) {
    if (path != null && path.isNotEmpty) {
      debugPrint("Notification tapped, navigating to: $path");
      if (onNotificationTap != null) {
        onNotificationTap!(path);
      }
    }
  }
}
