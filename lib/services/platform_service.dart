import 'package:flutter/foundation.dart';

/// Abstract platform service for handling platform-specific functionality
abstract class IPlatformService {
  /// Check if notifications are supported on this platform
  bool get notificationsSupported;

  /// Check if local file system is supported
  bool get fileSystemSupported;

  /// Check if device location is supported
  bool get locationSupported;

  /// Check if device sensors are supported
  bool get sensorsSupported;

  /// Get platform identifier
  String get platformId;
}

/// Platform service implementation with platform detection
class PlatformService implements IPlatformService {
  static final PlatformService _instance = PlatformService._internal();

  factory PlatformService() => _instance;

  PlatformService._internal();

  @override
  bool get notificationsSupported => !kIsWeb;

  @override
  bool get fileSystemSupported => !kIsWeb;

  @override
  bool get locationSupported => !kIsWeb;

  @override
  bool get sensorsSupported => !kIsWeb;

  @override
  String get platformId {
    if (kIsWeb) return 'web';
    return 'mobile';
  }

  /// Determine if running on web
  static bool isWeb() => kIsWeb;

  /// Determine if running on mobile (Android/iOS)
  static bool isMobile() => !kIsWeb;

  /// Get more detailed platform info
  static String getDetailedPlatform() {
    if (kIsWeb) return 'web';
    return 'mobile';
  }
}

