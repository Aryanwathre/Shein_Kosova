import 'package:flutter/material.dart';
import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/models/CartItemModel.dart';
import 'package:shein_kosova/services/api_service.dart';

class CheckoutProvider extends ChangeNotifier {
  final OrdersApi ordersApi = ApiServiceManager().ordersApi;
  final CouponApi couponApi = ApiServiceManager().couponApi;

  AddressModel? selectedAddress;

  // Coupon state
  Map<String, dynamic>? appliedCoupon;
  bool isValidatingCoupon = false;
  String? couponErrorMessage;

  Future<bool> validateAndApplyCoupon(String code, double orderAmount) async {
    isValidatingCoupon = true;
    couponErrorMessage = null;
    notifyListeners();

    try {
      final res = await couponApi.validateCoupon(code, orderAmount);
      if (res.success && res.data != null && res.data!['valid'] == true) {
        appliedCoupon = res.data;
        isValidatingCoupon = false;
        notifyListeners();
        return true;
      } else {
        couponErrorMessage = res.message ?? res.data?['message'] ?? "Invalid coupon code";
        isValidatingCoupon = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      couponErrorMessage = "Error validating coupon";
      isValidatingCoupon = false;
      notifyListeners();
      return false;
    }
  }

  void removeCoupon() {
    appliedCoupon = null;
    couponErrorMessage = null;
    notifyListeners();
  }

  double getTotalWithDiscount(double subtotal) {
    if (appliedCoupon == null) return subtotal;
    
    double discountAmount = 0;
    if (appliedCoupon!['discountAmount'] != null) {
      discountAmount = double.tryParse(appliedCoupon!['discountAmount'].toString()) ?? 0;
    }
    
    return subtotal - discountAmount;
  }

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
  String? redirectUrl;
  String? orderId;

  Future<bool> placeOrder() async {
    if (selectedAddress == null) {
      errorMessage = "Please select an address";
      debugPrint('❌ Checkout Error: $errorMessage');
      notifyListeners();
      return false;
    }

    isPlacingOrder = true;
    errorMessage = null;
    redirectUrl = null;
    orderId = null;
    notifyListeners();

    debugPrint('🛒 Placing order with:');
    debugPrint('  📍 Address ID: ${selectedAddress!.id}');
    debugPrint('  💳 Payment Method: $paymentMethod');
    debugPrint('  🏷️ Coupon Code: ${appliedCoupon?['code']}');

    final res = await ordersApi.createOrder(
      addressId: selectedAddress!.id,
      paymentMethod: paymentMethod,
      couponCode: appliedCoupon?['code'],
    );

    debugPrint('📊 API Response:');
    debugPrint('  Success: ${res.success}');
    debugPrint('  Status Code: ${res.statusCode}');
    debugPrint('  Message: ${res.message}');
    debugPrint('  Error: ${res.error}');
    debugPrint('  Data: ${res.data}');

    isPlacingOrder = false;

    // Determine success based on API response status AND success field in body if present
    bool apiSuccess = res.success;
    if (res.data is Map<String, dynamic> && res.data!.containsKey('success')) {
      apiSuccess = res.data!['success'] == true;
    }

    if (!apiSuccess) {
      errorMessage = res.message ?? res.data?['message'] ?? res.error ?? "Failed to place order";
      debugPrint('❌ Order placement failed: $errorMessage');
    } else {
      debugPrint('✅ Order placed successfully!');
      // Clear coupon and other checkout state on success
      appliedCoupon = null;
      couponErrorMessage = null;
      isValidatingCoupon = false;

      // Extract redirect URL and order ID from response
      if (res.data is Map<String, dynamic>) {
        redirectUrl = res.data?['redirect_url'];
        orderId = res.data?['order_id']?.toString();
        debugPrint('🔗 Redirect URL: $redirectUrl');
        debugPrint('📝 Order ID: $orderId');
      }
    }

    notifyListeners();
    return apiSuccess;
  }
}