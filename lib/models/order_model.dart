import 'package:shein_kosova/models/AddressModel.dart';
import 'package:shein_kosova/models/order_item_model.dart';

class OrderModel {
  final String orderId;
  final double totalAmount;
  final String status;
  final String? paymentStatus;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryDate;
  final DateTime? deliveredAt;
  final List<OrderItemModel> items;
  final AddressModel address;

  OrderModel({
    required this.orderId,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    required this.createdAt,
    this.estimatedDeliveryDate,
    this.deliveredAt,
    required this.items,
    required this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json["orderId"].toString(),
      totalAmount: (json["totalAmount"] ?? 0).toDouble(),
      status: json["status"] ?? "",
      paymentStatus: json["paymentStatus"],
      paymentMethod: json["paymentMethod"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      estimatedDeliveryDate: DateTime.tryParse(json["estimatedDeliveryDate"] ?? ""),
      deliveredAt: DateTime.tryParse(json["deliveredAt"] ?? ""),
      items: (json["items"] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      address: AddressModel.fromJson(json["address"] ?? {}),
    );
  }
}

class PaginatedOrderResponse {
  final List<OrderModel> orders;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool isLastPage;

  PaginatedOrderResponse({
    required this.orders,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.isLastPage,
  });

  factory PaginatedOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedOrderResponse(
      orders: (json['content'] as List<dynamic>? ?? [])
          .map((order) => OrderModel.fromJson(order))
          .toList(),
      page: json['pageable']?['pageNumber'] ?? 0,
      size: json['pageable']?['pageSize'] ?? 10,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? 0,
      isLastPage: json['last'] ?? true,
    );
  }
}
