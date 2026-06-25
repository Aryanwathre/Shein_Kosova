import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/order_model.dart';
import 'package:shein_kosova/provider/orders_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  OrdersProvider? _ordersProvider;

  @override
  void initState() {
    super.initState();
    _ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersProvider?.getAllOrders(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = _ordersProvider;
      if (provider != null && !provider.isLoadingMore && !provider.isLastPage) {
        provider.loadMoreOrders();
      }
    }
  }

  Future<void> _onRefresh() async {
    await _ordersProvider?.getAllOrders(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final orders = ordersProvider.orders;

    return Scaffold(
      appBar: AppBar(title: const Text("My Orders")),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (ordersProvider.state == CheckoutState.loading && orders.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: ShimmerWidget.rectangular(height: 150),
                    ),
                    childCount: 5,
                  ),
                ),
              )
            else if (ordersProvider.state == CheckoutState.error && orders.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load orders',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ordersProvider.errorMessage ?? 'Something went wrong',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ordersProvider.getAllOrders(refresh: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (orders.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text("No orders found")),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return OrderCard(order: order);
                    },
                    childCount: orders.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
              if (ordersProvider.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/order-details', extra: order);
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  StatusChip(status: order.status),
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
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.items.first.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      "x${order.items.first.quantity}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getBackgroundColor(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getTextColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange.shade100;
      case 'PROCESSING':
      case 'CONFIRMED':
      case 'SHIPPED': return Colors.blue.shade100;
      case 'OUT_FOR_DELIVERY': return Colors.lightBlue.shade100;
      case 'DELIVERED': return Colors.green.shade100;
      case 'CANCELLED': return Colors.red.shade100;
      default: return Colors.grey.shade200;
    }
  }

  Color _getTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'PROCESSING':
      case 'CONFIRMED':
      case 'SHIPPED': return Colors.blue;
      case 'OUT_FOR_DELIVERY': return Colors.lightBlue;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }
}

