import 'package:flutter/material.dart';
import '../../../models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order #${order.orderId}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderItems(order),
            const SizedBox(height: 20),
            _buildOrderStatus(order.status),
            const SizedBox(height: 20),
            _buildDeliveryAddress(),
            const Divider(height: 32),
            _buildPriceDetails(order.totalAmount),
            const Divider(height: 32),
            _buildOrderInfo(order),
            const SizedBox(height: 20),
            _buildCancelButton(context, order),
          ],
        ),
      ),
    );
  }

  // --- Ordered Items ---
  Widget _buildOrderItems(OrderModel order) {
    if (order.items.isEmpty) {
      return const Center(child: Text("No items found in this order"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ordered Items",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: order.items.map((item) {
              return ListTile(
                // leading: ClipRRect(
                //   borderRadius: BorderRadius.circular(8),
                //   child: Image.network(
                //     item.image,
                //     width: 60,
                //     height: 60,
                //     fit: BoxFit.cover,
                //     errorBuilder: (_, __, ___) =>
                //     const Icon(Icons.image_not_supported),
                //   ),
                // ),
                title: Text(item.productName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text("Qty: ${item.quantity}"),
                trailing: Text("€${item.price * item.quantity}"),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Order Status Stepper ---
  Widget _buildOrderStatus(String status) {
    final statusSteps = ["Placed", "Processing", "Shipped", "Delivered"];
    int currentStep = statusSteps.indexOf(status);
    if (currentStep < 0) currentStep = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Order Status",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Stepper(
          physics: const NeverScrollableScrollPhysics(),
          currentStep: currentStep,
          controlsBuilder: (_, __) => const SizedBox(),
          steps: statusSteps
              .map(
                (s) => Step(
              title: Text(s),
              content: const SizedBox(),
              isActive: statusSteps.indexOf(s) <= currentStep,
              state: statusSteps.indexOf(s) <= currentStep
                  ? StepState.complete
                  : StepState.indexed,
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  // --- Delivery Address (Placeholder for now) ---
  Widget _buildDeliveryAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("Delivery Address",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text("123, Green Park Street\nMumbai, Maharashtra - 400001"),
      ],
    );
  }

  // --- Price Details ---
  Widget _buildPriceDetails(double total) {
    const double deliveryFee = 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Price Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Items Total"),
            Text("€${total.toStringAsFixed(2)}"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Delivery Fee"),
            Text("€0.00"),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total Amount",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text("€${(total + deliveryFee).toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // --- Order Info (ID, Payment, Date) ---
  Widget _buildOrderInfo(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order ID: ${order.orderId}",
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text("Payment Status: ${order.paymentStatus}",
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          "Ordered On: ${order.createdAt.toLocal().toString().split(' ').first}",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // --- Cancel Button ---
  Widget _buildCancelButton(BuildContext context, OrderModel order) {
    final isCancellable =
        order.status.toLowerCase() == 'placed' || order.status.toLowerCase() == 'processing';

    return Center(
      child: ElevatedButton(
        onPressed: isCancellable
            ? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order Cancelled")),
          );
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCancellable ? Colors.red : Colors.grey,
          minimumSize: const Size(200, 48),
        ),
        child: const Text("Cancel Order"),
      ),
    );
  }
}
