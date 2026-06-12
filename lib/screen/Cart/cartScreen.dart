import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:input_quantity/input_quantity.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/models/CartItemModel.dart';
import 'package:shein_kosova/provider/cart_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';
import 'package:shein_kosova/utils/formatedPrice.dart';
import 'package:shein_kosova/utils/responsive_helper.dart';
import 'package:shein_kosova/widgets/shimmer_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Shopping Cart"),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Selector<CartProvider, CartState>(
          selector: (_, provider) => provider.state,
          builder: (context, state, child) {
            if (state == CartState.loading) {
              return _buildLoadingState();
            }
            if (state == CartState.error) {
              return _buildErrorState(context);
            }

            return isDesktop
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const ShimmerWidget.rectangular(height: 100),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load cart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Selector<CartProvider, String?>(
            selector: (_, provider) => provider.errorMessage,
            builder: (context, error, _) => Text(
              error ?? "An error occurred while loading your cart",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<CartProvider>().loadCart(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Selector<CartProvider, List<CartItem>>(
      selector: (_, provider) => provider.items,
      builder: (context, items, child) {
        if (items.isEmpty) {
          return _buildEmptyCart();
        }
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<CartProvider>().loadCart(showLoading: false),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _CartItemTile(item: items[index]),
                ),
              ),
            ),
            const _BottomCheckoutBar(),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Selector<CartProvider, List<CartItem>>(
      selector: (_, provider) => provider.items,
      builder: (context, items, child) {
        if (items.isEmpty) {
          return _buildEmptyCart();
        }
        return Row(
          children: [
            // Left side - Cart items
            Expanded(
              flex: 2,
              child: RefreshIndicator(
                onRefresh: () => context.read<CartProvider>().loadCart(showLoading: false),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _CartItemTileDesktop(item: items[index]),
                ),
              ),
            ),
            // Right side - Order summary
            Container(
              width: 350,
              color: Colors.grey[50],
              child: const _OrderSummarySidebar(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                "Your cart is empty",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Start adding items to your cart!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/shop'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  Future<void> _showDeleteConfirmation(BuildContext context, String cartItemId) async {
    final provider = context.read<CartProvider>();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item"),
        content: Text("Are you sure you want to remove '${item.name}' from your cart?"),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.removeFromCart(cartItemId);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CartProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.image.isEmpty
                  ? Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.image,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerWidget.rectangular(height: 80, width: 80),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(context, item.id.toString()),
                        child: const Icon(Icons.delete_outline, size: 22),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Size: ${item.size}"),
                  if (item.color != null && item.color!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text("Color: ${item.color}"),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      styledPrice(item.price),
                      const Spacer(),
                      InputQty.int(
                        maxVal: 40,
                        minVal: 0,
                        initVal: item.quantity,
                        steps: 1,
                        qtyFormProps: const QtyFormProps(enableTyping: false),
                        decoration: QtyDecorationProps(
                          minusBtn: Icon(Icons.remove, color: AppColors.primary),
                          plusBtn: Icon(Icons.add, color: AppColors.primary),
                        ),
                        onQtyChanged: (value) {
                          if (value == null) return;
                          if (value <= 0) {
                            _showDeleteConfirmation(context, item.id.toString());
                          } else {
                            provider.updateQuantity(item.id.toString(), value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTileDesktop extends StatelessWidget {
  final CartItem item;
  const _CartItemTileDesktop({required this.item});

  Future<void> _showDeleteConfirmation(BuildContext context, String cartItemId) async {
    final provider = context.read<CartProvider>();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Item"),
        content: Text("Are you sure you want to remove '${item.name}' from your cart?"),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.removeFromCart(cartItemId);
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.image.isEmpty
                ? Container(
                    height: 120,
                    width: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : CachedNetworkImage(
                    imageUrl: item.image,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerWidget.rectangular(height: 120, width: 120),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, item.id.toString()),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.delete_outline, size: 20),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("Size: ${item.size}"),
                    ),
                    const SizedBox(width: 12),
                    if (item.color != null && item.color!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("Color: ${item.color}"),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    styledPrice(item.price, fontSize: 16),
                    Row(
                      children: [
                        const Text("Quantity: ", style: TextStyle(fontSize: 14)),
                        SizedBox(
                          width: 140,
                          child: InputQty.int(
                            maxVal: 40,
                            minVal: 0,
                            initVal: item.quantity,
                            steps: 1,
                            qtyFormProps: const QtyFormProps(enableTyping: false),
                            decoration: QtyDecorationProps(
                              minusBtn: Icon(Icons.remove, color: AppColors.primary, size: 18),
                              plusBtn: Icon(Icons.add, color: AppColors.primary, size: 18),
                            ),
                            onQtyChanged: (value) {
                              if (value == null) return;
                              if (value <= 0) {
                                _showDeleteConfirmation(context, item.id.toString());
                              } else {
                                provider.updateQuantity(item.id.toString(), value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummarySidebar extends StatelessWidget {
  const _OrderSummarySidebar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _SummaryRow(
            label: "Subtotal",
            value: Selector<CartProvider, double>(
              selector: (_, provider) => provider.totalAmount,
              builder: (context, total, _) => styledPrice(total),
            ),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: "Shipping",
            value: const Text(
              "Free",
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: "Tax",
            value: const Text(
              "Calculated at checkout",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: "Total",
            value: Selector<CartProvider, double>(
              selector: (_, provider) => provider.totalAmount,
              builder: (context, total, _) => styledPrice(
                total,
                fontSize: 18,
              ),
            ),
            isBold: true,
          ),
          const SizedBox(height: 24),
          Selector<CartProvider, bool>(
            selector: (_, provider) => provider.isUpdating,
            builder: (context, isUpdating, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : () => context.push('/checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/shop'),
              child: const Text('Continue Shopping'),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Free shipping on orders over \$50",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[600],
          ),
        ),
        value,
      ],
    );
  }
}

class _BottomCheckoutBar extends StatelessWidget {
  const _BottomCheckoutBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Selector<CartProvider, int>(
                  selector: (_, provider) => provider.itemCount,
                  builder: (context, count, _) => Text(
                    "Total ($count items):",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Selector<CartProvider, double>(
                  selector: (_, provider) => provider.totalAmount,
                  builder: (context, total, _) => styledPrice(total, color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: Selector<CartProvider, bool>(
              selector: (_, provider) => provider.isUpdating,
              builder: (context, isUpdating, child) {
                return ElevatedButton(
                  onPressed: isUpdating ? null : () => context.push('/checkout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

