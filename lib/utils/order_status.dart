import 'package:flutter/material.dart';

/// Order statuses shown to customers (Albanian — English), matching the website
/// and admin. Older backend values are shown as their closest status.
class OrderStatusInfo {
  final String al;
  final String en;
  final Color color;
  const OrderStatusInfo(this.al, this.en, this.color);

  String get label => '$al — $en';
}

const Map<String, OrderStatusInfo> _statuses = {
  'PENDING': OrderStatusInfo('Në pritje', 'Pending', Colors.orange),
  'CONFIRMED': OrderStatusInfo('E konfirmuar', 'Confirmed', Colors.indigo),
  'SHIPPED': OrderStatusInfo('E nisur', 'Shipped', Colors.blue),
  'DELIVERED': OrderStatusInfo('E dorëzuar', 'Delivered', Colors.green),
  'CANCELLED': OrderStatusInfo('E anuluar', 'Cancelled', Colors.red),
  'RETURNED': OrderStatusInfo('E kthyer', 'Returned', Colors.brown),
  'REFUND_COMPLETED': OrderStatusInfo('E rimbursuar', 'Refunded', Colors.purple),
};

const Map<String, String> _legacy = {
  'PROCESSING': 'CONFIRMED',
  'OUT_FOR_DELIVERY': 'SHIPPED',
  'PAYMENT_FAILED': 'CANCELLED',
  'RETURN_REQUESTED': 'RETURNED',
  'REFUND_INITIATED': 'REFUND_COMPLETED',
  'AWAITING_PAYMENT': 'PENDING', // card checkout not paid yet
};

OrderStatusInfo? orderStatusInfo(String status) {
  final s = status.toUpperCase();
  return _statuses[_legacy[s] ?? s];
}

String orderStatusLabel(String status) =>
    orderStatusInfo(status)?.label ?? status.replaceAll('_', ' ');

Color orderStatusColor(String status) => orderStatusInfo(status)?.color ?? Colors.grey;

/// "COD" -> "Cash on Delivery", "CARD" -> "Card".
String paymentMethodLabel(String? method) {
  switch ((method ?? '').toUpperCase()) {
    case 'COD':
      return 'Cash on Delivery';
    case 'CARD':
      return 'Card';
    case 'GOOGLE_PAY':
      return 'Google Pay';
    case 'APPLE_PAY':
      return 'Apple Pay';
    default:
      return 'N/A';
  }
}

/// Payment status in plain words (cash on delivery stays "Pending" until delivered).
String paymentStatusLabel(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'PAID':
    case 'SUCCESS':
      return 'Paid';
    case 'PENDING':
      return 'Pending';
    case 'UNPAID':
      return 'Unpaid';
    case 'FAILED':
      return 'Failed';
    case 'REFUNDED':
      return 'Refunded';
    default:
      return 'N/A';
  }
}
