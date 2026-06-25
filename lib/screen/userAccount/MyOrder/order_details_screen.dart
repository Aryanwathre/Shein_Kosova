import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/constants/routes.dart';
import 'package:shein_kosova/models/order_model.dart';
import 'package:shein_kosova/provider/orders_provider.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? order;
  final String? orderId;

  const OrderDetailsScreen({super.key, this.order, this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _order = widget.order;
    } else if (widget.orderId != null) {
      _fetchOrder();
    }
  }

  Future<void> _fetchOrder() async {
    setState(() => _isLoading = true);
    final order = await Provider.of<OrdersProvider>(context, listen: false)
        .fetchOrderById(widget.orderId!);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: const Center(child: Text("Order not found")),
      );
    }

    final order = _order!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if(context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.landing);
            }
          },
        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order ID: #${order.orderId}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ordered on ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (order.estimatedDeliveryDate != null || order.estimatedDeliveryDate.toString().isEmpty  )
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Estimated Delivery: ${DateFormat('dd MMM yyyy').format(order.estimatedDeliveryDate!)}",
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  if (order.deliveredAt != null || order.deliveredAt.toString().isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            "Delivered on: ${DateFormat('dd MMM yyyy').format(order.deliveredAt!)}",
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
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
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Phone: ${order.address.contactNumber}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Payment Info
            _buildSection(
              title: "Payment Information",
              content: Row(
                children: [
                  Icon(Icons.payment, size: 24, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.paymentMethod ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "Status: ${order.paymentStatus ?? 'N/A'}",
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
                                  width: 80,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                )
                              : CachedNetworkImage(
                                  imageUrl: item.productMainImageUrl,
                                  width: 80,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 80,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                            errorWidget: (context, url, error) => Container(
                              width: 80,
                              height: 100,
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
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (item.size.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Size: ${item.size}",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 11),
                                      ),
                                    ),
                                  if (item.size.isNotEmpty && item.color.isNotEmpty)
                                    const SizedBox(width: 8),
                                  if (item.color.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Color: ${item.color}",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Qty: ${item.quantity}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  styledPrice(item.price, fontSize: 15),
                                ],
                              ),
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
                  _priceRow("Shipping Fee:", 0.00),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Grand Total:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      styledPrice(order.totalAmount, fontSize: 18, color: Colors.black,),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold)),
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
      case 'CONFIRMED':
        color = Colors.indigo;
        break;
      case 'PROCESSING':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
