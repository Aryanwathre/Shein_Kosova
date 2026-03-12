import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shein_kosova/constants/web_config.dart';

/// Custom HTTP client that handles CORS for web platform
class CorsHttpClient extends http.BaseClient {
  final http.Client _innerClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add CORS headers for web requests
    if (kIsWeb) {
      _addCorsHeaders(request);
    }

    // Add web-specific headers
    _addWebHeaders(request);

    try {
      return await _innerClient.send(request);
    } catch (e) {
      if (kIsWeb && e.toString().contains('CORS')) {
        // Log CORS error for debugging
        debugPrint('CORS Error: $e');
        debugPrint('Request URL: ${request.url}');
        debugPrint('Request Headers: ${request.headers}');
      }
      rethrow;
    }
  }

  /// Add CORS headers to request
  void _addCorsHeaders(http.BaseRequest request) {
    request.headers['Access-Control-Allow-Credentials'] = 'true';
    request.headers['Access-Control-Allow-Headers'] =
        'Content-Type, Authorization, X-Requested-With';
    request.headers['Access-Control-Allow-Methods'] =
        'GET, POST, PUT, DELETE, OPTIONS';
  }

  /// Add web-specific headers
  void _addWebHeaders(http.BaseRequest request) {
    if (kIsWeb) {
      request.headers['X-Requested-With'] = 'XMLHttpRequest';
    }
  }
}

/// GET request with CORS support
Future<http.Response> corsGet(
  Uri url, {
  Map<String, String>? headers,
}) {
  final client = CorsHttpClient();
  final finalHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...WebConfig.getSecureHeaders(additional: headers),
  };
  return client.get(url, headers: finalHeaders).then((response) {
    return response;
  });
}

/// POST request with CORS support
Future<http.Response> corsPost(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
}) {
  final client = CorsHttpClient();
  final finalHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...WebConfig.getSecureHeaders(additional: headers),
  };
  return client.post(url, headers: finalHeaders, body: body).then((response) {
    return response;
  });
}

/// PUT request with CORS support
Future<http.Response> corsPut(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
}) {
  final client = CorsHttpClient();
  final finalHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...WebConfig.getSecureHeaders(additional: headers),
  };
  return client.put(url, headers: finalHeaders, body: body).then((response) {
    return response;
  });
}

/// DELETE request with CORS support
Future<http.Response> corsDelete(
  Uri url, {
  Map<String, String>? headers,
}) {
  final client = CorsHttpClient();
  final finalHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...WebConfig.getSecureHeaders(additional: headers),
  };
  return client.delete(url, headers: finalHeaders).then((response) {
    return response;
  });
}

