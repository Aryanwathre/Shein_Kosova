import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shein_kosova/models/ReviewModel.dart';
import 'package:shein_kosova/models/category_model.dart';
import 'package:shein_kosova/models/order_model.dart';

// ==================== CONSTANTS ====================
class AppConstants {
  static const String baseUrl = "https://api.s-kosova.com";
  static const String appApiLink = "$baseUrl/api/v1/";
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration tokenValidityDuration = Duration(hours: 24);
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
  final DateTime expiryTime;
  final DateTime createdAt;

  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiryTime,
    required this.createdAt,
  });

  factory TokenData.fromApiResponse(Map<String, dynamic> json) {
    final now = DateTime.now();
    return TokenData(
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      createdAt: now,
      expiryTime: now.add(AppConstants.tokenValidityDuration),
    );
  }

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
    return DateTime.now().isAfter(expiryTime.subtract(const Duration(minutes: 5)));
  }

  bool get isCompletelyExpired {
    return DateTime.now().isAfter(expiryTime);
  }

  Duration get timeUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) {
      return Duration.zero;
    }
    return expiryTime.difference(now);
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
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  static bool _isRefreshing = false;
  static final List<Function> _refreshCallbacks = [];

  static Future<TokenData?> getTokenData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenDataKey);
      if (tokenJson == null) return null;
      return TokenData.fromStoredJson(jsonDecode(tokenJson));
    } catch (e) {
      debugPrint('Error getting token data: $e');
      await clearAllData();
      return null;
    }
  }

  static Future<void> saveTokenData(TokenData tokenData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenDataKey, jsonEncode(tokenData.toJson()));
      await prefs.setString(_accessTokenKey, tokenData.accessToken);
      await prefs.setString(_refreshTokenKey, tokenData.refreshToken);
    } catch (e) {
      debugPrint('Error saving token data: $e');
    }
  }

  static Future<void> saveTokensFromResponse(Map<String, dynamic> responseData) async {
    try {
      final tokenData = TokenData.fromApiResponse(responseData);
      await saveTokenData(tokenData);
    } catch (e) {
      debugPrint('Error saving tokens from response: $e');
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);
      if (userJson == null) return null;
      return jsonDecode(userJson);
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenDataKey);
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  static Future<bool> isTokenValid() async {
    final tokenData = await getTokenData();
    return tokenData != null && !tokenData.isExpired;
  }

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

  static Future<String?> getValidAccessToken() async {
    final tokenData = await getTokenData();
    if (tokenData == null) return null;
    if (!tokenData.isExpired) return tokenData.accessToken;
    final refreshed = await _refreshAccessToken();
    if (refreshed) {
      final newTokenData = await getTokenData();
      return newTokenData?.accessToken;
    }
    return null;
  }

  static Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 100));
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return await isTokenValid();
    }
    _isRefreshing = true;
    try {
      final tokenData = await getTokenData();
      if (tokenData == null || tokenData.refreshToken.isEmpty) return false;
      final response = await ApiClient().client.post(
        Uri.parse('${AppConstants.appApiLink}auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": tokenData.refreshToken}),
      ).timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = await compute(jsonDecode, response.body);
        await saveTokensFromResponse(responseData['data'] ?? responseData);
        for (final callback in _refreshCallbacks) { callback(); }
        _refreshCallbacks.clear();
        return true;
      } else {
        await clearAllData();
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<bool> forceRefreshToken() async {
    _isRefreshing = false;
    return await _refreshAccessToken();
  }
}

// ==================== BASE API CLASS ====================
abstract class BaseApi {
  final http.Client client = ApiClient().client;

  Future<ApiResponse<T>> makeRequest<T>({
    required Future<http.Response> Function(Map<String, String> headers) request,
    required T Function(dynamic json) parser,
    bool requireAuth = true,
    int maxRetries = 1,
  }) async {
    int retryCount = 0;
    while (retryCount <= maxRetries) {
      try {
        final headers = await TokenManager.getHeaders(requireAuth: requireAuth);
        final response = await request(headers).timeout(AppConstants.requestTimeout);

        if ((response.statusCode == 401 || response.statusCode == 403) && requireAuth && retryCount == 0) {
          final refreshed = await TokenManager.forceRefreshToken();
          if (refreshed) {
            retryCount++;
            continue;
          }
          await TokenManager.clearAllData();
          return ApiResponse.error("Session expired. Please login again.", statusCode: 401);
        }
        return await _handleResponse(response, parser);
      } catch (e) {
        return ApiResponse.error("Unexpected error: $e");
      }
    }
    return ApiResponse.error("Max retries exceeded");
  }

  Future<ApiResponse<T>> _handleResponse<T>(http.Response response, T Function(dynamic json) parser) async {
    debugPrint("API Response [${response.statusCode}]: ${response.body}");
    try {
      final decoded = response.body.isNotEmpty ? await compute(jsonDecode, response.body) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(parser(decoded), statusCode: response.statusCode);
      }
      final message = _extractErrorMessage(decoded) ?? _getDefaultErrorMessage(response.statusCode);
      return ApiResponse.error(message, statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse.error("Failed to parse response: $e");
    }
  }

  String? _extractErrorMessage(dynamic errorData) {
    try {
      if (errorData == null) return null;
      if (errorData['error'] != null) return errorData['error'].toString();
      if (errorData['message'] != null) return errorData['message'].toString();
      if (errorData['detail'] != null) return errorData['detail'].toString();
      if (errorData['error_description'] != null) return errorData['error_description'].toString();
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400: return 'Bad request';
      case 401: return 'Authentication failed';
      case 403: return 'Access forbidden';
      case 404: return 'Resource not found';
      case 500: return 'Server error';
      default: return 'Request failed with status: $statusCode';
    }
  }
}

// ==================== APIs ====================

class RegisterUserApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> registerUser({
    required String firstName, required String lastName, required String email, required String password,
  }) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}auth/register'),
        headers: headers,
        body: jsonEncode({"firstName": firstName, "lastName": lastName, "email": email, "password": password}),
      ),
      parser: (json) {
        final data = json['data'] ?? json;
        if (data['accessToken'] != null) {
          TokenManager.saveTokensFromResponse(data);
          if (data['user'] != null) TokenManager.saveUserData(data['user']);
        }
        return json;
      },
    );
  }
}

class LoginUserApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> loginUser({required String email, required String password}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}auth/login'),
        headers: headers,
        body: jsonEncode({"email": email, "password": password}),
      ),
      parser: (json) {
        final data = json['data'] ?? json;
        if (data['accessToken'] != null) {
          TokenManager.saveTokensFromResponse(data);
          if (data['user'] != null) TokenManager.saveUserData(data['user']);
        }
        return json;
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}auth/change-password'),
        headers: headers,
        body: jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        }),
      ),
      parser: (json) => json is Map<String, dynamic> ? json : {},
    );
  }
}

class AddressApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addAddress({
    required String addressLine1, required String addressLine2, required String city,
    required String state, required String country, required String postalCode,
    required String receiverName, required String contactNumber, required bool isDefault,
  }) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}address'),
        headers: headers,
        body: jsonEncode({
          "addressLine1": addressLine1, "addressLine2": addressLine2, "city": city,
          "state": state, "country": country, "postalCode": postalCode,
          "receiverName": receiverName, "contact_number": contactNumber, "isDefault": isDefault,
        }),
      ),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getAddress() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}address'), headers: headers),
      parser: (json) => List<Map<String, dynamic>>.from(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress({
    required String id, required String addressLine1, required String addressLine2, required String city,
    required String state, required String country, required String postalCode,
    required String receiverName, required String contactNumber, required bool isDefault,
  }) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.put(
        Uri.parse('${AppConstants.appApiLink}address/$id'),
        headers: headers,
        body: jsonEncode({
          "addressLine1": addressLine1, "addressLine2": addressLine2, "city": city,
          "state": state, "country": country, "postalCode": postalCode,
          "receiverName": receiverName, "contact_number": contactNumber, "isDefault": isDefault,
        }),
      ),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAddress({required String id}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.delete(Uri.parse('${AppConstants.appApiLink}address/$id'), headers: headers),
      parser: (json) => json,
    );
  }
}

class ProductsApi extends BaseApi {
  Future<ApiResponse<dynamic>> getProducts() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getProductById({required String productId}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/$productId'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<dynamic>> getProductByCategory(String categoryId) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/category/$categoryId'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getFeaturedProducts() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/featured'), headers: headers),
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getNewArrivals() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/new-arrivals'), headers: headers),
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }
}

class CategoriesApi extends BaseApi {
  Future<ApiResponse<CategoryResponse>> getCategories({int page = 0, int size = 20, String sortBy = "name", String sortDir = "asc"}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(
        Uri.parse('${AppConstants.appApiLink}categories?page=$page&size=$size&sortBy=$sortBy&sortDir=$sortDir'),
        headers: headers,
      ),
      parser: (json) => CategoryResponse.fromJson(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCategoryById({required String categoryId}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}categories/$categoryId'), headers: headers),
      parser: (json) => json['data'] ?? json,
    );
  }
}

class SearchApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> searchProducts({
    String? query, String? categoryId, double? minPrice, double? maxPrice,
    double? minRating, int? page, int? size, String? sortBy, String? sortDir, String? sizeRange, String? color,
  }) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) {
        final queryParams = <String, String>{
          if (query != null) 'query': query,
          if (categoryId != null) 'categoryId': categoryId,
          if (minPrice != null) 'minPrice': minPrice.toString(),
          if (maxPrice != null) 'maxPrice': maxPrice.toString(),
          if (minRating != null) 'minRating': minRating.toString(),
          if (page != null) 'page': page.toString(),
          if (size != null) 'size': size.toString(),
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDir != null) 'sortDir': sortDir,
          if (sizeRange != null) 'product_size': sizeRange,
          if (color != null) 'color': color,
        };
        final uri = Uri.parse('${AppConstants.appApiLink}products/search').replace(queryParameters: queryParams);
        return client.get(uri, headers: headers);
      },
      parser: (json) => json is Map<String, dynamic> ? json : {},
    );
  }

  Future<ApiResponse<List<dynamic>>> getCategorySearch({required String query}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(
        Uri.parse('${AppConstants.appApiLink}categories/search?q=${Uri.encodeQueryComponent(query)}'),
        headers: headers,
      ),
      parser: (json) {
        if (json is List) return json;
        if (json is Map && json['data'] is List) return json['data'];
        return [];
      },
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getPopularSearches() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}search/popular'), headers: headers),
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }
}

class ColorsApi extends BaseApi {
  Future<ApiResponse<List<String>>> getAvailableColors() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}color'), headers: headers),
      parser: (json) => List<String>.from(json['data'] ?? json ?? []),
    );
  }
}

class ProfileApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}profile'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String firstName, required String lastName, required String email,
    String? phoneNumber, String? dateOfBirth, String? gender,
  }) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.put(
        Uri.parse('${AppConstants.appApiLink}profile'),
        headers: headers,
        body: jsonEncode({
          "firstName": firstName, "lastName": lastName, "email": email,
          if (phoneNumber != null) "phoneNumber": phoneNumber,
          if (dateOfBirth != null) "dateOfBirth": dateOfBirth,
          if (gender != null) "gender": gender,
        }),
      ),
      parser: (json) => json,
    );
  }
}

class CartApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addToCart({required int productId, required int quantity, required String size, String? color}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}cart/items'),
        headers: headers,
        body: jsonEncode({"productId": productId, "quantity": quantity, "size": size, if (color != null) "color": color}),
      ),
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCart() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}cart'), headers: headers),
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCartItem({required String cartItemId, required int quantity}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.patch(
        Uri.parse('${AppConstants.appApiLink}cart/items/$cartItemId'),
        headers: headers,
        body: jsonEncode({"quantity": quantity}),
      ),
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteCartItem({required String cartItemId}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.delete(Uri.parse('${AppConstants.appApiLink}cart/items/$cartItemId'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> clearCart() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.delete(Uri.parse('${AppConstants.appApiLink}cart'), headers: headers),
      parser: (json) => json,
    );
  }
}

class WishlistApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addToWishlist({required int productId}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(Uri.parse('${AppConstants.appApiLink}wishlist/$productId'), headers: headers),
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getWishlist() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}wishlist'), headers: headers),
      parser: (json) => Map<String, dynamic>.from(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> removeFromWishlist({required int wishlistId}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.delete(Uri.parse('${AppConstants.appApiLink}wishlist/$wishlistId'), headers: headers),
      parser: (json) => json,
    );
  }
}

class OrdersApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> createOrder({required String addressId, required String paymentMethod}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}orders/create'),
        headers: headers,
        body: jsonEncode({"addressId": addressId, "paymentMethod": paymentMethod}),
      ),
      parser: (json) => json is Map<String, dynamic> ? json : {'data': json},
    );
  }

  Future<ApiResponse<List<OrderModel>>> getOrders() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}orders'), headers: headers),
      parser: (json) {
        final List<dynamic> content = json["content"] ?? [];
        return content.map((e) => OrderModel.fromJson(e)).toList();
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getOrderById({required String orderId}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}orders/$orderId/status'), headers: headers),
      parser: (json) => json is Map<String, dynamic> ? json : {'data': json},
    );
  }
}

class ReviewsApi extends BaseApi {
  Future<ApiResponse<Map<String, dynamic>>> addReview({required String productId, required double rating, required String comment}) async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.post(
        Uri.parse('${AppConstants.appApiLink}products/$productId/reviews'),
        headers: headers,
        body: jsonEncode({"rating": rating, "comment": comment}),
      ),
      parser: (json) => json['data'] ?? json,
    );
  }

  Future<ApiResponse<PaginatedReviewResponse>> getProductReviews({required String productId, int page = 0, int size = 10, int? rating}) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) {
        final queryParams = {'page': page.toString(), 'size': size.toString(), if (rating != null) 'rating': rating.toString()};
        final uri = Uri.parse('${AppConstants.appApiLink}products/$productId/reviews').replace(queryParameters: queryParams);
        return client.get(uri, headers: headers);
      },
      parser: (json) => PaginatedReviewResponse.fromJson(json),
    );
  }
}


class SizesApi extends BaseApi {
  Future<ApiResponse<List<String>>> getAvailableSizes() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}sizes'), headers: headers),
      parser: (json) => List<String>.from(json['data'] ?? json ?? []),
    );
  }
}

class NotificationsApi extends BaseApi {
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}notifications'), headers: headers),
      parser: (json) => List<Map<String, dynamic>>.from(json['data'] ?? json ?? []),
    );
  }
}

class HomeApi extends BaseApi {
  Future<ApiResponse<dynamic>> getProductsByTag(String tag) async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/tag?tag=$tag'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<String>>> getProductsTags() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}products/tags'), headers: headers),
      parser: (json) => List<String>.from(json),
    );
  }

  Future<ApiResponse<List<CategoryModel>>> getRandomCategories() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}home/categories/random'), headers: headers),
      parser: (json) => (json as List).map((item) => CategoryModel.fromJson(item)).toList(),
    );
  }

  Future<ApiResponse<dynamic>> getForYouProducts() async {
    return makeRequest(
      requireAuth: true,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}home/for-you'), headers: headers),
      parser: (json) => json,
    );
  }

  Future<ApiResponse<List<dynamic>>> getAllBanners() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}banners'), headers: headers),
      parser: (json) => json,
    );
  }


  Future<ApiResponse<dynamic>> getDeals() async {
    return makeRequest(
      requireAuth: false,
      request: (headers) => client.get(Uri.parse('${AppConstants.appApiLink}home/deals'), headers: headers),
      parser: (json) => json,
    );
  }
}

// ==================== API SERVICE MANAGER ====================
class ApiServiceManager {
  static final ApiServiceManager _instance = ApiServiceManager._internal();
  factory ApiServiceManager() => _instance;
  ApiServiceManager._internal();

  final RegisterUserApi registerApi = RegisterUserApi();
  final LoginUserApi loginApi = LoginUserApi();
  final AddressApi addressApi = AddressApi();
  final ProductsApi productsApi = ProductsApi();
  final CategoriesApi categoriesApi = CategoriesApi();
  final SearchApi searchApi = SearchApi();
  final ProfileApi profileApi = ProfileApi();
  final CartApi cartApi = CartApi();
  final WishlistApi wishlistApi = WishlistApi();
  final OrdersApi ordersApi = OrdersApi();
  final ReviewsApi reviewsApi = ReviewsApi();
  final SizesApi sizesApi = SizesApi();
  final ColorsApi colorsApi = ColorsApi();
  final NotificationsApi notificationsApi = NotificationsApi();
  final HomeApi homeApi = HomeApi();

  Future<bool> isUserLoggedIn() async { return await TokenManager.isTokenValid(); }
  Future<Map<String, dynamic>?> getCurrentUser() async { return await TokenManager.getUserData(); }
  Future<void> logout() async { await TokenManager.clearAllData(); }
  void dispose() { ApiClient().dispose(); }
}
