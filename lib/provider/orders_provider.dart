import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

enum CheckoutState { idle, loading, success, error }

class OrdersProvider with ChangeNotifier {
  final OrdersApi _ordersApi = OrdersApi();

  CheckoutState _state = CheckoutState.idle;
  String? _errorMessage;
  List<OrderModel> _orders = [];
  Map<String, dynamic>? _orderStatus;

  CheckoutState get state => _state;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get orders => _orders;
  Map<String, dynamic>? get orderStatus => _orderStatus;

  void _setState(CheckoutState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(CheckoutState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// ✅ Create a new order
  Future<void> createOrder({
    required String addressId,
    required String paymentMethod,
  }) async {
    _setState(CheckoutState.loading);

    try {
      final response = await _ordersApi.createOrder(
        addressId: addressId,
        paymentMethod: paymentMethod,
      );

      if (response.success) {
        _setState(CheckoutState.success);
      } else {
        _setError(response.message ?? 'Failed to create order');
      }
    } catch (e) {
      _setError('Error creating order: $e');
    }
  }

  /// ✅ Fetch all orders
  Future<void> getAllOrders() async {
    _setState(CheckoutState.loading);

    try {
      final response = await _ordersApi.getOrders();
      print("🟢 API Response: ${response.data?.first.orderId}");

      if (response.success && response.data != null) {

        _orders = List<OrderModel>.of(response.data!);
        print("✅ Parsed Orders: ${_orders}");
        _clearError();
        _setState(CheckoutState.success);
      } else {
        _setError(response.message ?? 'Failed to load orders');
      }
    } catch (e) {
      _setError('Error fetching orders: $e');
    }
  }



  /// ✅ Get order status by ID
  Future<void> getOrderStatus(String orderId) async {
    _setState(CheckoutState.loading);

    try {
      final response = await _ordersApi.getOrderById(orderId: orderId);

      if (response.success && response.data != null) {
        _orderStatus = response.data!;
        _clearError();
        _setState(CheckoutState.success);
      } else {
        _setError(response.message ?? 'Failed to fetch order status');
      }
    } catch (e) {
      _setError('Error fetching order status: $e');
    }
  }

  /// ✅ Reset provider state
  void reset() {
    _orders = [];
    _orderStatus = null;
    _errorMessage = null;
    _state = CheckoutState.idle;
    notifyListeners();
  }
}
