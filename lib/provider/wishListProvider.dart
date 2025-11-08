import 'package:flutter/material.dart';
import '../models/WishlistItemModel.dart';
import '../services/api_service.dart';

enum WishlistState { initial, loading, loaded, error, updating }

class WishlistProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  List<WishlistItemModel> _wishlistItems = [];
  WishlistState _state = WishlistState.initial;
  String? _errorMessage;
  int _wishlistItemID = 0;

  // Getters
  List<WishlistItemModel> get wishlistItems => _wishlistItems;
  int get WishlistItemID => _wishlistItemID;
  WishlistState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == WishlistState.loading;
  bool get isUpdating => _state == WishlistState.updating;
  bool get hasError => _state == WishlistState.error;

  /// Check if a product (by productId) is in the wishlist
  bool isProductInWishlist(int productId) {
    print("Checking if product $productId is in wishlist");
    print("Current wishlist items: ${_wishlistItems.map((item) => item.productId).toList()}");
    return _wishlistItems.any((item) => item.productId == productId);
  }

  /// Load the user's wishlist from the API
  Future<void> loadWishlist() async {
    _setState(WishlistState.loading);
    _clearError();

    try {
      final response = await _api.wishlistApi.getWishlist();

      if (response.success && response.data != null) {
        final data = response.data;

        // Log the raw API response
        debugPrint("Wishlist raw response: $data");

        // ✅ Handle the correct response format
        if (data is Map<String, dynamic>) {
          final items = data!['items'] as List<dynamic>?;

          _wishlistItems = List<WishlistItemModel>.from(
            items?.map((item) => WishlistItemModel.fromJson(item)) ?? [],
          );

          debugPrint("Parsed wishlist items: ${_wishlistItems.length}");
          _setState(WishlistState.loaded);
        } else {
          _setError('Invalid API response format');
        }
      } else {
        _setError(response.error ?? 'Failed to load wishlist');
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
    }
  }


  /// Add a product to the wishlist
  Future<void> addToWishlist(int productId) async {
    _setState(WishlistState.updating);
    try {
      final response = await _api.wishlistApi.addToWishlist(productId: productId);
      if (response.success) {
        await loadWishlist(); // Refresh wishlist
      } else {
        _setError(response.error ?? 'Could not add to wishlist');
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
    }
  }

  /// Remove a product from the wishlist using its productId
  Future<void> removeProductFromWishlist(int productId) async {
    _setState(WishlistState.updating);
    try {
      final item = _wishlistItems.firstWhere(
            (element) => element.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );

      final response = await _api.wishlistApi.removeFromWishlist(wishlistId: item.wishlistItemId);

      if (response.success) {
        _wishlistItems.removeWhere((i) => i.productId == productId);
        _setState(WishlistState.loaded);
      } else {
        _setError(response.error ?? 'Could not remove item from wishlist');
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
    }
  }



  // ---- State management helpers ----

  void _setState(WishlistState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(WishlistState.error);
    debugPrint("WishlistProvider Error: $error");
  }

  void _clearError() {
    _errorMessage = null;
  }
}
