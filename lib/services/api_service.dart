import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/Category.dart';
import '../models/ProductModel.dart';
import '../models/order_model.dart';

// ==================== CONSTANTS ====================
class AppConstants {
  static const String appApiLink = "http://66.29.130.49:8080/api/v1/";
  static const String baseUrl = "http://66.29.130.49:8080/";
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration tokenValidityDuration = Duration(hours: 24); // Client-side calculation
}

// ==================== RESPONSE MODELS ====================
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

// ==================== TOKEN MODEL ====================
class TokenData {
  final String accessToken;
  final String refreshToken;
  final DateTime expiryTime; // Calculated locally
  final DateTime createdAt;   // Track when token was created

  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTime,
    required this.createdAt,
  });

  // Create TokenData from API response (without expiry time)
  factory TokenData.fromApiResponse(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TokenData(
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      createdAt: now,
      expiryTime: now.add(AppConstants.tokenValidityDuration), // Calculate locally
    );
  }

  // Create TokenData from stored JSON (with all fields)
  factory TokenData.fromStoredJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiryTime: DateTime.parse(json['expiryTime']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiryTime': expiryTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isExpired {
    // Check if token expires in next 5 minutes to refresh proactively
    return DateTime.now().isAfter(expiryTime.subtract(Duration(minutes: 5)));
  }

  bool get isCompletelyExpired {
    return DateTime.now().isAfter(expiryTime);
  }

  // Get remaining time until expiry
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) {
      return Duration.zero;
    }
    return expiryTime.difference(now);
  }

  // Check if token was created recently (within last minute)
  bool get isRecentlyCreated {
    return DateTime.now().difference(createdAt).inMinutes < 1;
  }
}

// ==================== HTTP CLIENT SINGLETON ====================
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  http.Client get client => _client;

  void dispose() {
    _client.close();
  }
}

// ==================== TOKEN MANAGER ====================
class TokenManager {
  static const String _tokenDataKey = 'token_data';
  static const String _userDataKey = 'user_data';

  // Prevent multiple simultaneous refresh requests
  static bool _isRefreshing = false;
  static List<Function> _refreshCallbacks = [];

  static Future<TokenData?> getTokenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenDataKey);

      if (tokenJson == null) return null;

      final tokenMap = jsonDecode(tokenJson);
      return TokenData.fromStoredJson(tokenMap);
    } catch (e) {
      print('Error getting token data: $e');
      // Clear corrupted data
      await _clearCorruptedData();
      return null;
    }
  }

  static Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenDataKey);
      print('Cleared corrupted token data');
    } catch (e) {
      print('Error clearing corrupted data: $e');
    }
  }

  static Future<String?> getAccessToken() async {
    final tokenData = await getTokenData();
    return tokenData?.accessToken;
  }

  static Future<String?> getRefreshToken() async {
    final tokenData = await getTokenData();
    return tokenData?.refreshToken;
  }

  static Future<void> saveTokenData(TokenData tokenData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenDataKey, jsonEncode(tokenData.toJson()));
      print('Tokens saved successfully. Expires at: ${tokenData.expiryTime}');
    } catch (e) {
      print('Error saving token data: $e');
    }
  }

  // Save tokens from API response (calculate expiry time locally)
  static Future<void> saveTokensFromResponse(Map<String, dynamic> responseData) async {
    try {
      final tokenData = TokenData.fromApiResponse(responseData);
      await saveTokenData(tokenData);
      print('Tokens saved from API response. Valid for ${AppConstants.tokenValidityDuration}');
    } catch (e) {
      print('Error saving tokens from response: $e');
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);

      if (userJson == null) return null;

      return jsonDecode(userJson);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenDataKey);
      await prefs.remove(_userDataKey);
      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  static Future<bool> isTokenValid() async {
    final tokenData = await getTokenData();
    return tokenData != null && !tokenData.isExpired;
  }

  static Future<bool> hasValidRefreshToken() async {
    final tokenData = await getTokenData();
    return tokenData != null && tokenData.refreshToken.isNotEmpty;
  }

  // Get token info for debugging
  static Future<String> getTokenInfo() async {
    final tokenData = await getTokenData();
    if (tokenData == null) {
      return 'No token data available';
    }

    final timeRemaining = tokenData.timeUntilExpiry;
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;

    return 'Token expires in: ${hours}h ${minutes}m (at ${tokenData.expiryTime})';
  }

  // Get headers with automatic token refresh
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getValidAccessToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, String>> getHeaders({bool requireAuth = true}) async {
    if (requireAuth) {
      return await getAuthHeaders();
    }
    return {"Content-Type": "application/json"};
  }

  // Get valid access token with automatic refresh
  static Future<String?> getValidAccessToken() async {
    final tokenData = await getTokenData();

    if (tokenData == null) {
      print('No token data available');
      return null;
    }

    // If token is not expired, return it
    if (!tokenData.isExpired) {
      final timeRemaining = tokenData.timeUntilExpiry;
      print('Token valid for ${timeRemaining.inMinutes} more minutes');
      return tokenData.accessToken;
    }

    // If token is expired, try to refresh
    print('Access token expired ${DateTime.now().difference(tokenData.expiryTime)} ago, attempting refresh...');
    final refreshed = await _refreshAccessToken();

    if (refreshed) {
      final newTokenData = await getTokenData();
      return newTokenData?.accessToken;
    }

    return null;
  }

  // Refresh access token using refresh token
  static Future<bool> _refreshAccessToken() async {
    // Prevent multiple simultaneous refresh requests
    if (_isRefreshing) {
      print('Token refresh already in progress, waiting...');

      // Wait for ongoing refresh to complete
      await Future.delayed(Duration(milliseconds: 100));
      while (_isRefreshing) {
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Check if refresh was successful
      return await isTokenValid();
    }

    _isRefreshing = true;

    try {
      final tokenData = await getTokenData();

      if (tokenData == null || tokenData.refreshToken.isEmpty) {
        print('No refresh token available');
        return false;
      }

      print('Refreshing token using refresh token...');
      final client = ApiClient().client;
      final response = await client.post(
        Uri.parse('${AppConstants.appApiLink}auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "refreshToken": tokenData.refreshToken,
        }),
      ).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);

        // Handle different possible response structures
        final tokenResponseData = responseData['data'] ?? responseData;

        // Create new token data with locally calculated expiry
        await saveTokensFromResponse(tokenResponseData);

        print('Token refreshed successfully. New token valid for ${AppConstants.tokenValidityDuration}');

        // Execute queued callbacks
        for (final callback in _refreshCallbacks) {
          callback();
        }
        _refreshCallbacks.clear();

        return true;
      } else {
        print('Token refresh failed: ${response.statusCode} - ${response.body}');

        // If refresh fails, clear all tokens (user needs to login again)
        await clearAllData();
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Force refresh token (useful for testing or manual refresh)
  static Future<bool> forceRefreshToken() async {
    _isRefreshing = false; // Reset flag
    return await _refreshAccessToken();
  }

  // Check if token will expire soon (within next hour)
  static Future<bool> willExpireSoon() async {
    final tokenData = await getTokenData();
    if (tokenData == null) return true;

    final timeUntilExpiry = tokenData.timeUntilExpiry;
    return timeUntilExpiry.inHours < 1;
  }

  // Get time until token expires (for UI display)
  static Future<Duration?> getTimeUntilExpiry() async {
    final tokenData = await getTokenData();
    return tokenData?.timeUntilExpiry;
  }
}

// ==================== BASE API CLASS ====================
abstract class BaseApi {
  final http.Client client = ApiClient().client;

  Future<ApiResponse<T>> makeRequest<T>({
    required Future<http.Response> Function() request,
    required T Function(Map<String, dynamic>) parser,
    bool requireAuth = true,
    int maxRetries = 1,
  }) async {
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        if (requireAuth) {
          final validToken = await TokenManager.getValidAccessToken();
          if (validToken == null) {
            return ApiResponse.error(
              'Authentication failed. Please login again.',
              statusCode: 401,
            );
          }
        }

        final response = await request().timeout(AppConstants.requestTimeout);

        // 👇 Handle 401 or 403 (token expired or invalid)
        if ((response.statusCode == 401 || response.statusCode == 403) &&
            requireAuth &&
            retryCount == 0) {
          print('Received ${response.statusCode}, attempting token refresh...');

          final refreshSuccess = await TokenManager.forceRefreshToken();
          if (refreshSuccess) {
            retryCount++;
            continue; // Retry request with new token
          } else {
            await TokenManager.clearAllData();
            return ApiResponse.error(
              'Session expired. Please login again.',
              statusCode: response.statusCode,
            );
          }
        }

        // Handle all other responses
        return _handleResponse<T>(response, parser);

      } on SocketException {
        return ApiResponse.error('No internet connection');
      } on HttpException {
        return ApiResponse.error('HTTP error occurred');
      } on FormatException {
        return ApiResponse.error('Invalid response format');
      } catch (e) {
        return ApiResponse.error('Unexpected error: ${e.toString()}');
      }
    }

    return ApiResponse.error('Max retries exceeded');
  }

  ApiResponse<T> _handleResponse<T>(
      http.Response response,
      T Function(Map<String, dynamic>) parser,
      ) {
    print('API Response [${response.statusCode}]: ${response.body}');

    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isNotEmpty) {
          try {
            final jsonData = jsonDecode(response.body);
            final data = parser(jsonData);
            return ApiResponse.success(data, statusCode: response.statusCode);
          } catch (e) {
            return ApiResponse.error('Failed to parse response: ${e.toString()}');
          }
        }
        return ApiResponse.success(null as T, statusCode: response.statusCode);

      default:
        final errorMessage = _extractErrorMessage(response.body);
        final defaultMessage = _getDefaultErrorMessage(response.statusCode);

        return ApiResponse.error(
          errorMessage ?? defaultMessage,
          statusCode: response.statusCode,
        );
    }
  }

  String? _extractErrorMessage(String responseBody) {
    try {
      if (responseBody.isEmpty) return null;
      final errorData = jsonDecode(responseBody);

      if (errorData['error'] != null) return errorData['error'].toString();
      if (errorData['message'] != null) return errorData['message'].toString();
      if (errorData['detail'] != null) return errorData['detail'].toString();
      if (errorData['error_description'] != null)
        return errorData['error_description'].toString();

      if (errorData['errors'] != null) {
        if (errorData['errors'] is List) {
          final errors = errorData['errors'] as List;
          if (errors.isNotEmpty) return errors.take(3).join('\n');
        } else if (errorData['errors'] is Map) {
          final errors = errorData['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
            return firstError.toString();
          }
        }
      }

      if (errorData['data'] != null && errorData['data']['message'] != null) {
        return errorData['data']['message'].toString();
      }

      return null;
    } catch (e) {
      print('Error parsing error response: $e');
      return null;
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Authentication failed';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 422:
        return 'Validation error';
      case 500:
        return 'Server error';
      default:
        return 'Request failed with status: $statusCode';
    }
  }
}

// ==================== AUTHENTICATION APIs ====================

class RegisterUserApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      requireAuth: false,
      request: () async {
        final headers = await TokenManager.getHeaders(requireAuth: false);
        final request = {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "password": password,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}auth/register'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) {
        // Save tokens and user data after successful registration
        _saveAuthData(json);
        return json;
      },
    );
  }

  void _saveAuthData(Map<String, dynamic> responseData) {
    try {
      // Handle different possible response structures
      final authData = responseData['data'] ?? responseData;

      if (authData['accessToken'] != null && authData['refreshToken'] != null) {
        // Save tokens with locally calculated expiry time
        TokenManager.saveTokensFromResponse(authData);

        // Save user data if available
        if (authData['user'] != null) {
          TokenManager.saveUserData(authData['user']);
        }

        print('Auth data saved successfully after registration ');
        print('User data: ${authData['user']}');
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }
}

class LoginUserApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> loginUser({
    required String email,
    required String password,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      requireAuth: false,
      request: () async {
        final headers = await TokenManager.getHeaders(requireAuth: false);
        final request = {
          "email": email,
          "password": password,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}auth/login'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) {
        // Save tokens and user data after successful login
        _saveAuthData(json);
        return json;
      },
    );
  }

  void _saveAuthData(Map<String, dynamic> responseData) {
    try {
      // Handle different possible response structures
      final authData = responseData['data'] ?? responseData;

      if (authData['accessToken'] != null && authData['refreshToken'] != null) {
        // Save tokens with locally calculated expiry time
        TokenManager.saveTokensFromResponse(authData);

        // Save user data if available
        if (authData['user'] != null) {
          TokenManager.saveUserData(authData['user']);
        }

        print('Auth data saved successfully after login');
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }
}

class RefreshTokenApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> refreshToken({
    required String refreshToken,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      requireAuth: false,
      request: () async {
        final headers = await TokenManager.getHeaders(requireAuth: false);
        final request = {
          "refreshToken": refreshToken,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}auth/refresh'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) {
        // Save new tokens after successful refresh
        _saveRefreshData(json);
        return json;
      },
    );
  }

  void _saveRefreshData(Map<String, dynamic> responseData) {
    try {
      final authData = responseData['data'] ?? responseData;

      if (authData['accessToken'] != null && authData['refreshToken'] != null) {
        // Save tokens with locally calculated expiry time
        TokenManager.saveTokensFromResponse(authData);
        print('Tokens refreshed and saved successfully');
      }
    } catch (e) {
      print('Error saving refresh data: $e');
    }
  }
}

// ==================== ADDRESS API ====================
class AddressApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addAddress({
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "addressLine1": addressLine1,
          "addressLine2": addressLine2,
          "city": city,
          "state": state,
          "country": country,
          "postalCode": postalCode,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}address'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getAddress() async {
    try {
      // Get valid auth headers (includes token)
      final headers = await TokenManager.getAuthHeaders();

      final response = await client
          .get(Uri.parse('${AppConstants.appApiLink}address'), headers: headers)
          .timeout(AppConstants.requestTimeout);

      // --- Handle status codes ---
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final list = List<Map<String, dynamic>>.from(decoded);
          return ApiResponse.success(list);
        } else {
          return ApiResponse.error(
            'Unexpected response format — expected a List, got ${decoded.runtimeType}',
          );
        }
      } else if (response.statusCode == 401) {
        // Try token refresh once
        final refreshed = await TokenManager.forceRefreshToken();
        if (refreshed) {
          return getAddress(); // Retry
        }
        await TokenManager.clearAllData();
        return ApiResponse.error('Session expired. Please login again.');
      } else {
        return ApiResponse.error(
          'Server responded with ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP error occurred');
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error('Unexpected error: ${e.toString()}');
    }
  }



  Future<ApiResponse<Map<String, dynamic>>> updateAddress({
    required String id,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String country,
    required String postalCode,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "addressLine1": addressLine1,
          "addressLine2": addressLine2,
          "city": city,
          "state": state,
          "country": country,
          "postalCode": postalCode,
        };

        return client.put(
          Uri.parse('${AppConstants.appApiLink}address/$id'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAddress({
    required String id,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}address/$id'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }
}

// ==================== PRODUCTS API ====================
class ProductsApi extends BaseApi {
  Future getProducts() async {
   try {
      final headers = await TokenManager.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.appApiLink}products'),
        headers: headers,
      );

      if (response.statusCode == 200) {

        return response.body;
      } else {
        print('❌ Failed to fetch products: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error: $e');
      return ApiResponse.error('Error fetching products: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getProductById({
    required String productId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}products/$productId'),
          headers: headers,
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future getProductByCategory(String categoryId) async {
    try {
      final headers = await TokenManager.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.appApiLink}products/category/$categoryId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ Fetched products for category $categoryId');
        print('Response Body: ${response.body}');
        return response.body;
      } else {
        print('❌ Failed to fetch products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('⚠️ Error: $e');
      return [];
    }
  }



  Future<ApiResponse<List<Map<String, dynamic>>>> getFeaturedProducts() async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}products/featured'),
          headers: headers,
        );
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getNewArrivals() async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}products/new-arrivals'),
          headers: headers,
        );
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }
}

// ==================== CATEGORIES API ====================
class CategoriesApi extends BaseApi {
  Future<ApiResponse<CategoryResponse>> getCategories({
    int page = 0,
    int size = 20,
    String sortBy = "name",
    String sortDir = "asc",
  }) async {
    return makeRequest<CategoryResponse>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final uri = Uri.parse(
          '${AppConstants.appApiLink}categories?page=$page&size=$size&sortBy=$sortBy&sortDir=$sortDir',
        );
        return client.get(uri, headers: headers);
      },
      parser: (json) => CategoryResponse.fromJson(json),
    );
  }


  Future<ApiResponse<Map<String, dynamic>>> getCategoryById({
    required String categoryId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}categories/$categoryId'),
          headers: headers,
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }
}

// ==================== SEARCH API ====================
class SearchApi extends BaseApi {
  /// Searches for products with various filter options.
  Future<ApiResponse<List<Map<String, dynamic>>>> searchProducts({
    required String query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    int? page,
    int? limit,
  }) async {
    // The return type is now correctly a List
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();

        // Build query parameters
        final queryParams = <String, String>{
          'q': query,
          if (categoryId != null) 'categoryId': categoryId,
          if (minPrice != null) 'minPrice': minPrice.toString(),
          if (maxPrice != null) 'maxPrice': maxPrice.toString(),
          if (sortBy != null) 'sortBy': sortBy,
          if (page != null) 'page': page.toString(),
          if (limit != null) 'limit': limit.toString(),
        };

        final uri = Uri.parse('${AppConstants.appApiLink}products/search')
            .replace(queryParameters: queryParams);

        return client.get(uri, headers: headers);
      },
      // --- FIX IS HERE ---
      // The parser now correctly extracts the 'content' list from the JSON map.
      parser: (json) {
        if (json is Map<String, dynamic> && json.containsKey('content')) {
          // Safely cast the 'content' field to a List.
          final List<dynamic> contentList = (json['content'] as List<dynamic>?) ?? [];
          // Convert each item in the list to the expected Map type.
          return contentList.map((item) => item as Map<String, dynamic>).toList();
        }
        // If the structure is wrong, return an empty list to prevent crashes.
        return [];
      },
    );
  }

  /// Gets search suggestions based on the user's query.
  Future<ApiResponse<List<String>>> getSearchSuggestions({
    required String query,
  }) async {
    return makeRequest<List<String>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final encodedQuery = Uri.encodeQueryComponent(query);
        return client.get(
          Uri.parse('${AppConstants.appApiLink}search/suggestions?q=$encodedQuery'),
          headers: headers,
        );
      },
      // Assuming this endpoint returns a simple list of strings.
      // If it also returns a nested object, apply the same fix as above.
      parser: (json) => List<String>.from(json['data'] ?? json ?? []),
    );
  }

  /// Gets a list of popular search terms.
  Future<ApiResponse<List<Map<String, dynamic>>>> getPopularSearches() async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}search/popular'),
          headers: headers,
        );
      },
      // Assuming this endpoint returns a simple list.
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }
}

// ==================== PROFILE API ====================
class ProfileApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}profile'),
          headers: headers,
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          if (phoneNumber != null) "phoneNumber": phoneNumber,
          if (dateOfBirth != null) "dateOfBirth": dateOfBirth,
          if (gender != null) "gender": gender,
        };

        return client.put(
          Uri.parse('${AppConstants.appApiLink}profile'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        };

        return client.put(
          Uri.parse('${AppConstants.appApiLink}profile/password'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage({
    required String imagePath,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        headers.remove('Content-Type'); // Let multipart set its own content type

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.appApiLink}profile/image'),
        );

        request.headers.addAll(headers);
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));

        final streamedResponse = await client.send(request);
        return http.Response.fromStream(streamedResponse);
      },
      parser: (json) => json['data'] ?? json,
    );
  }
}

// ==================== CART API ====================
class CartApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addToCart({
    required int productId,
    required int quantity,
    String? size,
    String? color,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "productId": productId,
          "quantity": quantity,
          if (size != null) "size": size,
          if (color != null) "color": color,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}cart/items'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCart() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}cart'),
          headers: headers,
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCartItem({
    required String cartItemId,
    required int quantity,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {"quantity": quantity};

        return client.patch(
          Uri.parse('${AppConstants.appApiLink}cart/items/$cartItemId'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteCartItem({
    required String cartItemId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}cart/items/$cartItemId'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> clearCart() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}cart'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> applyCoupon({
    required String couponCode,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {"couponCode": couponCode};

        return client.post(
          Uri.parse('${AppConstants.appApiLink}cart/coupon'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> removeCoupon() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}cart/coupon'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }
}

// ==================== WISHLIST API ====================
class WishlistApi extends BaseApi {
  /// Add a product to the wishlist
  Future<ApiResponse<Map<String, dynamic>>> addToWishlist({
    required int productId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();

        return client.post(
          Uri.parse('${AppConstants.appApiLink}wishlist/$productId'),
          headers: headers,
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  /// Get all wishlist items
  Future<ApiResponse<Map<String, dynamic>>> getWishlist() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}wishlist'),
          headers: headers,
        );
      },
      parser: (json) => Map<String, dynamic>.from(json),
    );
  }


  /// Remove a product from the wishlist by its productId
  Future<ApiResponse<Map<String, dynamic>>> removeFromWishlist({
    required int wishlistId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();

        return client.delete(
          Uri.parse('${AppConstants.appApiLink}wishlist/$wishlistId'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }
}

// ==================== ORDERS API ====================
class OrdersApi extends BaseApi {
  /// ✅ Create Order
  /// POST /orders/create
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required String addressId,
    required String paymentMethod,
  }) async {
    try {
      final headers = await TokenManager.getAuthHeaders();
      final body = {
        "addressId": addressId,
        "paymentMethod": paymentMethod,
      };

      final response = await client.post(
        Uri.parse('${AppConstants.appApiLink}orders/create'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(
            json is Map<String, dynamic> ? json : {'data': json});
      } else {
        return ApiResponse.error(
            'Failed with status code ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error creating order: $e');
    }
  }

  /// ✅ Get All Orders
  /// GET /api/v1/orders
  Future<ApiResponse<List<OrderModel>>> getOrders() async {
    try {
      final headers = await TokenManager.getAuthHeaders();

      final response = await client.get(
        Uri.parse('${AppConstants.appApiLink}orders'),
        headers: headers,
      );

      debugPrint("API Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          // Map each JSON object to an OrderModel
          final orders = decoded.map((e) => OrderModel.fromJson(e)).toList();
          return ApiResponse.success(orders);
        } else {
          return ApiResponse.error('Unexpected response format (expected List)');
        }
      } else {
        return ApiResponse.error(
          'Failed to load orders: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      debugPrint('Error fetching orders: $e');
      debugPrint('Stack trace: $stack');
      return ApiResponse.error('Error fetching orders: $e');
    }
  }



  Future<ApiResponse<Map<String, dynamic>>> getOrderById({
    required String orderId,
  }) async {
    try {
      final headers = await TokenManager.getAuthHeaders();

      final response = await client.get(
        Uri.parse('${AppConstants.appApiLink}orders/$orderId/status'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        return ApiResponse.success(
            json is Map<String, dynamic> ? json : {'data': json});
      } else {
        return ApiResponse.error(
            'Failed to fetch order status: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching order status: $e');
    }
  }
}

// ==================== PAYMENTS API ====================
class PaymentsApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "orderId": orderId,
          "amount": amount,
          "currency": currency,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}payments/intent'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "paymentIntentId": paymentIntentId,
          "paymentMethodId": paymentMethodId,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}payments/confirm'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentMethods() async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}payments/methods'),
          headers: headers,
        );
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addPaymentMethod({
    required String type,
    required Map<String, dynamic> details,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "type": type,
          "details": details,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}payments/methods'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deletePaymentMethod({
    required String paymentMethodId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}payments/methods/$paymentMethodId'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }
}

// ==================== REVIEWS API ====================
class ReviewsApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "productId": productId,
          "rating": rating,
          "comment": comment,
          if (images != null) "images": images,
        };

        return client.post(
          Uri.parse('${AppConstants.appApiLink}reviews'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getProductReviews({
    required String productId,
    int? page,
    int? limit,
    int? rating,
  }) async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();

        final queryParams = <String, String>{
          if (page != null) 'page': page.toString(),
          if (limit != null) 'limit': limit.toString(),
          if (rating != null) 'rating': rating.toString(),
        };

        final uri = Uri.parse('${AppConstants.appApiLink}products/$productId/reviews')
            .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

        return client.get(uri, headers: headers);
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getUserReviews() async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.get(
          Uri.parse('${AppConstants.appApiLink}reviews/user'),
          headers: headers,
        );
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        final request = {
          "rating": rating,
          "comment": comment,
        };

        return client.put(
          Uri.parse('${AppConstants.appApiLink}reviews/$reviewId'),
          headers: headers,
          body: jsonEncode(request),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteReview({
    required String reviewId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}reviews/$reviewId'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }
}

// ==================== NOTIFICATIONS API ====================
class NotificationsApi extends BaseApi {
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications({
    bool? unreadOnly,
    int? page,
    int? limit,
  }) async {
    return makeRequest<List<Map<String, dynamic>>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();

        final queryParams = <String, String>{
          if (unreadOnly != null) 'unreadOnly': unreadOnly.toString(),
          if (page != null) 'page': page.toString(),
          if (limit != null) 'limit': limit.toString(),
        };

        final uri = Uri.parse('${AppConstants.appApiLink}notifications')
            .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

        return client.get(uri, headers: headers);
      },
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markAsRead({
    required String notificationId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.put(
          Uri.parse('${AppConstants.appApiLink}notifications/$notificationId/read'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> markAllAsRead() async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.put(
          Uri.parse('${AppConstants.appApiLink}notifications/read-all'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteNotification({
    required String notificationId,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.delete(
          Uri.parse('${AppConstants.appApiLink}notifications/$notificationId'),
          headers: headers,
        );
      },
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings({
    required Map<String, bool> settings,
  }) async {
    return makeRequest<Map<String, dynamic>>(
      request: () async {
        final headers = await TokenManager.getAuthHeaders();
        return client.put(
          Uri.parse('${AppConstants.appApiLink}notifications/settings'),
          headers: headers,
          body: jsonEncode(settings),
        );
      },
      parser: (json) => json['data'] ?? json,
    );
  }
}

// ==================== API SERVICE MANAGER ====================
class ApiServiceManager {
  static final ApiServiceManager _instance = ApiServiceManager._internal();
  factory ApiServiceManager() => _instance;
  ApiServiceManager._internal();

  // Authentication APIs
  final RegisterUserApi registerApi = RegisterUserApi();
  final LoginUserApi loginApi = LoginUserApi();
  final RefreshTokenApi refreshTokenApi = RefreshTokenApi();

  // Core APIs
  final AddressApi addressApi = AddressApi();
  final ProductsApi productsApi = ProductsApi();
  final CategoriesApi categoriesApi = CategoriesApi();
  final SearchApi searchApi = SearchApi();
  final ProfileApi profileApi = ProfileApi();

  // Shopping APIs
  final CartApi cartApi = CartApi();
  final WishlistApi wishlistApi = WishlistApi();
  final OrdersApi ordersApi = OrdersApi();
  final PaymentsApi paymentsApi = PaymentsApi();

  // Interaction APIs
  final ReviewsApi reviewsApi = ReviewsApi();
  final NotificationsApi notificationsApi = NotificationsApi();

  // Authentication status methods
  Future<bool> isUserLoggedIn() async {
    return await TokenManager.isTokenValid();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await TokenManager.getUserData();
  }

  // Token management methods
  Future<String> getTokenInfo() async {
    return await TokenManager.getTokenInfo();
  }

  Future<bool> willTokenExpireSoon() async {
    return await TokenManager.willExpireSoon();
  }

  Future<Duration?> getTimeUntilExpiry() async {
    return await TokenManager.getTimeUntilExpiry();
  }

  Future<bool> refreshToken() async {
    return await TokenManager.forceRefreshToken();
  }

  // Logout method
  Future<void> logout() async {
   try {
     await TokenManager.clearAllData();

    } catch (e) {
      debugPrint('Error during logout: $e');
    }

  }

  // Cleanup method
  void dispose() {
    ApiClient().dispose();
  }
}
