import 'package:shein_kosova/models/AddressModel.dart';
import 'order_item_model.dart';

class OrderModel {
  final String orderId;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final AddressModel address;

  OrderModel({
    required this.orderId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
    required this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json["orderId"].toString(),
      totalAmount: (json["totalAmount"] ?? 0).toDouble(),
      status: json["status"] ?? "",
      paymentStatus: json["paymentStatus"] ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      items: (json["items"] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      address: AddressModel.fromJson(json["address"] ?? {}),
    );
  }
}

