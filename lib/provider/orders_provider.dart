import 'package:flutter/foundation.dart';
import 'package:shein_kosova/models/order_model.dart';
import 'package:shein_kosova/services/api_service.dart';

enum CheckoutState { idle, loading, success, error }

class OrdersProvider with ChangeNotifier {
  final OrdersApi _ordersApi = OrdersApi();

  CheckoutState _state = CheckoutState.idle;
  String? _errorMessage;
  List<OrderModel> _orders = [];
  Map<String, dynamic>? _orderStatus;

  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoadingMore = false;

  CheckoutState get state => _state;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get orders => _orders;
  Map<String, dynamic>? get orderStatus => _orderStatus;
  bool get isLastPage => _isLastPage;
  bool get isLoadingMore => _isLoadingMore;

  void _setState(CheckoutState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(CheckoutState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// --------------------------------------------------
  ///  CREATE ORDER
  /// --------------------------------------------------
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

  /// --------------------------------------------------
  ///  GET ALL ORDERS (First Page)
  /// --------------------------------------------------
  Future<void> getAllOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _isLastPage = false;
    }
    
    if (_state == CheckoutState.loading) return;
    
    _setState(CheckoutState.loading);

    try {
      final response = await _ordersApi.getOrders(page: _currentPage);

      if (response.success && response.data != null) {
        if (refresh) {
          _orders = response.data!.orders;
        } else {
          // If not refresh, we probably want to replace for the "first" load
          _orders = response.data!.orders;
        }
        
        _isLastPage = response.data!.isLastPage;
        _currentPage = response.data!.page;

        _clearError();
        _setState(CheckoutState.success);
      } else {
        _setError(response.message ?? 'Failed to load orders');
      }
    } catch (e) {
      _setError('Error fetching orders: $e');
    }
  }

  /// --------------------------------------------------
  ///  LOAD MORE ORDERS (Pagination)
  /// --------------------------------------------------
  Future<void> loadMoreOrders() async {
    if (_isLoadingMore || _isLastPage) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _ordersApi.getOrders(page: nextPage);

      if (response.success && response.data != null) {
        _orders.addAll(response.data!.orders);
        _isLastPage = response.data!.isLastPage;
        _currentPage = response.data!.page;
        _clearError();
      } else {
        debugPrint('Failed to load more orders: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error loading more orders: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }


  /// --------------------------------------------------
  ///  GET ORDER STATUS
  /// --------------------------------------------------
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

  /// --------------------------------------------------
  ///  RESET PROVIDER
  /// --------------------------------------------------
  void reset() {
    _orders = [];
    _orderStatus = null;
    _errorMessage = null;
    _state = CheckoutState.idle;
    _currentPage = 0;
    _isLastPage = false;
    _isLoadingMore = false;
    notifyListeners();
  }
}
