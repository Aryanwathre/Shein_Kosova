import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shein_kosova/models/order_model.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ID: #${order.orderId}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ordered on ${DateFormat('dd MMM yyyy').format(order.createdAt)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(order.status),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Shipping Address
            _buildSection(
              title: "Shipping Address",
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.address.receiverName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(order.address.addressLine1),
                  if (order.address.addressLine2.isNotEmpty)
                    Text(order.address.addressLine2),
                  Text("${order.address.city}, ${order.address.state} ${order.address.postalCode}"),
                  Text(order.address.country),
                  const SizedBox(height: 4),
                  Text("Phone: ${order.address.contactNumber}"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Payment Info
            _buildSection(
              title: "Payment Information",
              content: Row(
                children: [
                  Icon(Icons.payment, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.paymentStatus.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "Status: ${order.paymentStatus}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Order Items
            _buildSection(
              title: "Order Items",
              content: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return GestureDetector(
                    onTap: () {
                      context.push('/products/${item.productId}');
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: item.productMainImageUrl.isEmpty
                              ? Container(
                                  width: 70,
                                  height: 90,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                )
                              : CachedNetworkImage(
                                  imageUrl: item.productMainImageUrl,
                                  width: 70,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 70,
                                    height: 90,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                            errorWidget: (context, url, error) => Container(
                              width: 70,
                              height: 90,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Size: ${item.size}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              if (item.color.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "Color: ${item.color}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "Qty: ${item.quantity}",
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              styledPrice(item.price, fontSize: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Order Summary / Total
            _buildSection(
              title: "Order Summary",
              content: Column(
                children: [
                  _priceRow("Items Total:", order.totalAmount),
                  _priceRow("Shipping:", 0.00),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Order Total:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      styledPrice(order.totalAmount, fontSize: 18, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            if (order.status.toUpperCase() == "PENDING" || order.status.toUpperCase() == "PROCESSING")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle cancellation
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text("Cancel Order"),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _priceRow(String label, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text("€${price.toStringAsFixed(2)}"),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        color = Colors.green;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      case 'SHIPPED':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
