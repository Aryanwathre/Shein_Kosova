import 'package:flutter/material.dart';

class LandingProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  int _cartCount = 0;

  int get selectedIndex => _selectedIndex;
  int get cartCount => _cartCount;

  void changePage(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void addToCart([int count = 1]) {
    _cartCount += count;
    notifyListeners();
  }

  void removeFromCart([int count = 1]) {
    if (_cartCount - count >= 0) {
      _cartCount -= count;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartCount = 0;
    notifyListeners();
  }
}
