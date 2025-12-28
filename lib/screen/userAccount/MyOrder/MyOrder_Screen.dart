import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';

import '../../../models/order_model.dart';
import '../../../provider/orders_provider.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
      Provider.of<OrdersProvider>(context, listen: false).getAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = Provider.of<OrdersProvider>(context);
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: ordersProvider.state == CheckoutState.loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No orders found"))
          : ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final order = orders[index];
          return buildOrderCard(context, order);
        },
      ),
    );
  }

  Widget buildOrderCard(BuildContext context, OrderModel order) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Order ID and Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        "Order #${order.orderId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          getStatusBackgroundColor(order.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: getStatusTextColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 🔹 Payment + Total + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment: ${order.paymentStatus}",
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  styledPrice(order.totalAmount, color: AppColors.textNormal),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                "Placed on: ${order.createdAt.toLocal().toString().split(' ').first}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              // 🔹 Order Items Preview
              if (order.items.isNotEmpty)
                ...order.items.take(1).map(
                      (item) => Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        "x${item.quantity}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

            ],
          ),
        ),
      ),
    );
  }

  Color getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade100;

      case 'PROCESSING':
        return Colors.blue.shade100;

      case 'CONFIRMED':
        return Colors.blue.shade100;

      case 'SHIPPED':
        return Colors.blue.shade100;

      case 'OUT_FOR_DELIVERY':
        return Colors.lightBlue.shade100;

      case 'DELIVERED':
        return Colors.green.shade100;

      case 'RETURN_REQUESTED':
        return Colors.purple.shade100;

      case 'RETURNED':
        return Colors.purple.shade100;

      case 'REFUND_INITIATED':
        return Colors.teal.shade100;

      case 'REFUND_COMPLETED':
        return Colors.teal.shade100;

      case 'CANCELLED':
        return Colors.red.shade100;

      default:
        return Colors.grey.shade200;
    }
  }


  Color getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;

      case 'PROCESSING':
        return Colors.blue;

      case 'CONFIRMED':
        return Colors.blue;

      case 'SHIPPED':
        return Colors.blue;

      case 'OUT_FOR_DELIVERY':
        return Colors.lightBlue;

      case 'DELIVERED':
        return Colors.green;

      case 'RETURN_REQUESTED':
        return Colors.purple;

      case 'RETURNED':
        return Colors.purple;

      case 'REFUND_INITIATED':
        return Colors.teal;

      case 'REFUND_COMPLETED':
        return Colors.teal;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }


}
