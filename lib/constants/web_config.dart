import 'package:flutter/foundation.dart';

/// Web-specific configuration for API calls, CORS, and security
class WebConfig {
  // API Configuration
  static const String apiBaseUrl = "https://api.s-kosova.com";
  static const String apiVersion = "v1";

  // Allowed origins for CORS
  static const List<String> allowedOrigins = [
    'https://s-kosova.com',
    'https://www.s-kosova.com',
    'http://localhost:3000',
    'http://127.0.0.1:3000',
  ];

  // CORS and Security Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get secure headers for web API calls
  static Map<String, String> getSecureHeaders({Map<String, String>? additional}) {
    final headers = Map<String, String>.from(defaultHeaders);

    // Add CORS and security headers for web
    if (kIsWeb) {
      headers['X-Requested-With'] = 'XMLHttpRequest';
      headers['Access-Control-Allow-Credentials'] = 'true';
      headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
      headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    }

    // Merge additional headers if provided
    if (additional != null) {
      headers.addAll(additional);
    }

    return headers;
  }

  /// Get API endpoint URL
  static String getApiEndpoint(String path) {
    final baseUrl = '$apiBaseUrl/api/$apiVersion/';
    return '$baseUrl$path';
  }

  /// Get timeout duration for web (slightly longer than mobile)
  static const Duration webRequestTimeout = Duration(seconds: 30);
  static const Duration mobileRequestTimeout = Duration(seconds: 15);

  /// Get appropriate timeout based on platform
  static Duration getRequestTimeout() {
    return kIsWeb ? webRequestTimeout : mobileRequestTimeout;
  }

  /// Check if running in production
  static bool isProduction() {
    return kReleaseMode;
  }

  /// Enable request logging in debug mode
  static bool shouldLogRequests() {
    return !isProduction();
  }

  /// Validate web URL - additional security check
  static bool isValidWebUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get CSP (Content Security Policy) headers for web
  static const String cspHeader =
    "default-src 'self'; "
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com; "
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
    "img-src 'self' data: https:; "
    "font-src 'self' https://fonts.gstatic.com; "
    "connect-src 'self' https://api.s-kosova.com https://www.googletagmanager.com;";

  /// Get CORS mode for web requests
  static String getCorsMode() {
    return 'cors';
  }

  /// Check if URL is from allowed origin
  static bool isAllowedOrigin(String origin) {
    return allowedOrigins.contains(origin);
  }
}

/// Environment-specific configuration
class EnvironmentConfig {
  static const String environment = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'production');

  static bool isDevelopment() => environment == 'development';
  static bool isProduction() => environment == 'production';
  static bool isStaging() => environment == 'staging';
}

