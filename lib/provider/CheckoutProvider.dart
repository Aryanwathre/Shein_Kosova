import 'package:flutter/material.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/models/CartItemModel.dart';
import 'package:shein_kosova/services/api_service.dart';

class CheckoutProvider extends ChangeNotifier {
  final OrdersApi ordersApi = ApiServiceManager().ordersApi;

  AddressModel? selectedAddress;

  void setAddress(AddressModel address) {
    selectedAddress = address;
    notifyListeners();
  }

  String shippingMethod = "standard"; // default

  final List<String> shippingOptions = [
    "standard",
    "express",
    "same_day",
  ];

  void setShipping(String method) {
    shippingMethod = method;
    notifyListeners();
  }

  String paymentMethod = "COD";

  final List<String> paymentMethods = [
    "COD",
    "CARD",
    "UPI",
  ];

  void setPayment(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  List<CartItem> cartItems = [];

  void setCartItems(List<CartItem> items) {
    cartItems = items;
    notifyListeners();
  }


  double get shippingCost {
    switch (shippingMethod) {
      case "express":
        return 80;
      case "same_day":
        return 120;
      default:
        return 40;
    }
  }

  bool isPlacingOrder = false;
  String? errorMessage;

  Future<bool> placeOrder() async {
    if (selectedAddress == null) {
      errorMessage = "Please select an address";
      notifyListeners();
      return false;
    }

    isPlacingOrder = true;
    errorMessage = null;
    notifyListeners();

    final res = await ordersApi.createOrder(
      addressId: selectedAddress!.id,
      paymentMethod: paymentMethod,
    );

    isPlacingOrder = false;

    if (!res.success) {
      errorMessage = res.message ?? "Failed to place order";
    }

    notifyListeners();
    return res.success;
  }
}
