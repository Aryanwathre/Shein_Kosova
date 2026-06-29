import 'package:flutter/material.dart';
import 'package:shein_kosova/models/CartItemModel.dart';
import 'package:shein_kosova/services/api_service.dart';

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
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // --- Core API Methods ---

  Future<void> loadCart({bool showLoading = true}) async {
    if (!await _api.isUserLoggedIn()) {
      _items = [];
      _setState(CartState.loaded);
      return;
    }

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
    required String sizes,
    String? color,
  }) async {
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.addToCart(
        productId: productId,
        quantity: quantity,
        size: sizes,
        color: color,
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

  Future<bool> updateQuantity(String cartItemId, int newQuantity) async {
    final index = _items.indexWhere((i) => i.id == cartItemId);
    if (index == -1) return false;

    final oldQuantity = _items[index].quantity;
    _items[index].quantity = newQuantity;
    notifyListeners();

    try {
      final response = await _api.cartApi.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
      );

      if (response.success) {
        await loadCart(showLoading: false);
        return true;
      } else {
        _items[index].quantity = oldQuantity;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _items[index].quantity = oldQuantity;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(String cartItemId) async {
    _setState(CartState.updating);
    try {
      final response = await _api.cartApi.deleteCartItem(cartItemId: cartItemId);
      if (response.success) {
        // Create a new list instead of modifying the existing one
        _items = _items.where((item) => item.id != cartItemId).toList();
        _setState(CartState.loaded); 
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
        _items = []; // Create a new empty list
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
      await updateQuantity(cartItemId, _items[index].quantity + 1);
    }
  }

  Future<void> decreaseQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      await updateQuantity(cartItemId, _items[index].quantity - 1);
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
