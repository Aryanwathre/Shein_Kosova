import 'package:flutter/material.dart';
import '../models/CartItemModel.dart'; // Ensure this path is correct
import '../services/api_service.dart'; // Ensure this path is correct

enum CartState {
  initial,
  loading,
  loaded,
  error,
  updating,
}

class CartProvider extends ChangeNotifier {
  final ApiServiceManager _api = ApiServiceManager();

  List<CartItem> _items = [];
  CartState _state = CartState.initial;
  String? _errorMessage;

  // Getters
  List<CartItem> get items => _items;
  CartState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CartState.loading;
  bool get isUpdating => _state == CartState.updating;
  bool get hasError => _state == CartState.error;
  int get itemCount => _items.length;

  double get totalAmount {
    // --- FIX IS HERE ---
    // Use the 'subtotal' from the API for the most accurate total.
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // --- Core API Methods ---

  Future<void> loadCart({bool showLoading = true}) async {
    if (showLoading) _setState(CartState.loading);

    try {
      final response = await _api.cartApi.getCart();

      if (response.success && response.data != null) {
        final List<dynamic> itemsData = (response.data!['items'] as List<dynamic>?) ?? [];
        _items = itemsData.map((data) => CartItem.fromJson(data)).toList();
        _setState(CartState.loaded);
        _clearError();
      } else {
        _setError(response.error ?? 'Failed to load cart');
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
    }
  }

  Future<bool> addToCart({
    required int productId,
    required int quantity,
  }) async {
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.addToCart(
        productId: productId,
        quantity: quantity,
      );

      if (response.success) {
        await loadCart(showLoading: false);
        return true;
      } else {
        _setError(response.error ?? 'Could not add item');
        return false;
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
      return false;
    }
  }

  // Use the unique cartItemId (which is an int in our model)
  Future<bool> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return await removeFromCart(cartItemId);
    }
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.updateCartItem(
        cartItemId: cartItemId.toString(), // API expects a String
        quantity: newQuantity,
      );
      if (response.success) {
        await loadCart(showLoading: false);
        return true;
      } else {
        _setError(response.error ?? 'Could not update quantity');
        return false;
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
      return false;
    }
  }

  // Use the unique cartItemId (which is an int in our model)
  Future<bool> removeFromCart(int cartItemId) async {
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.deleteCartItem(cartItemId: cartItemId.toString());
      if (response.success) {
        _items.removeWhere((item) => item.id == cartItemId.toString());
        _setState(CartState.loaded);
        notifyListeners(); // Manually notify after optimistic update
        return true;
      } else {
        _setError(response.error ?? 'Could not remove item');
        return false;
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
      return false;
    }
  }

  Future<bool> clearCart() async {
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.clearCart();
      if (response.success) {
        _items.clear();
        _setState(CartState.loaded);
        return true;
      } else {
        _setError(response.error ?? 'Failed to clear cart');
        return false;
      }
    } catch (e) {
      _setError('A network error occurred: ${e.toString()}');
      return false;
    }
  }

  // --- UI Helper Methods ---

  Future<void> increaseQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      await updateQuantity(int.parse(cartItemId), _items[index].quantity + 1);
    }
  }

  Future<void> decreaseQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      await updateQuantity(int.parse(cartItemId), _items[index].quantity - 1);
    }
  }

  // --- State Management Helpers ---

  void _setState(CartState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(CartState.error);
    debugPrint("CartProvider Error: $error");
  }

  void _clearError() {
    _errorMessage = null;
  }

  bool isProductInCart(int productId) {
    return _items.any((item) => item.productId == productId);
  }

}
